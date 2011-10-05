# encoding: UTF-8

require 'xapian-fu'

module Spontaneous::Search
  class Index

    attr_reader :name, :search_types

    def initialize(name, &definition)
      @name = name
      @search_types = base_search_types
      @include_pages = nil
      @exclude_pages = nil
      self.instance_eval(&definition) if definition
    end

    # Index DSL methods
    def include_pages(*page_list)
      @include_pages = page_list
    end

    def exclude_pages(*page_list)
      @exclude_pages = page_list
    end

    def include_types(*types)
      @search_types = resolve_type_list(types)
    end

    def exclude_types(*types)
      @search_types -= resolve_type_list(types)
    end
    # end Index DSL methods

    def create_db(revision)
      Database.create(self, revision)
    end

    def search(query, options = {})
      database.search(query, options)
    end

    def database(revision = Spontaneous::Site.published_revision)
      Database.new(self, revision)
    end

    # TODO: make setting the language part of the config
    def language
      :english
    end

    # Extract all indexable content from a page. Values are grouped across fields
    # or across field index groups
    def indexable_content(page)
      values = Hash.new { |h, k| h[k] = [] }
      # not sure that I need the include? test here as page.content only returns Pieces
      # and I'm not sure that there is a particular need to exclude Pieces from indexes
      pieces = [page].concat(page.content).select { |content| include?(content) }
      pieces.each do |content|
        content.fields.each do |field|
          prototype = field.prototype
          values[prototype.index_id(self)] << field.unprocessed_value if prototype.in_index?(self)
        end
      end
      result = Hash[ values.map { |id, values| [id, values.join("\n")] } ]
      result[:id] = page.id
      result
    end

    def fields
      field_lists = Hash.new { |h, k| h[k] = [] }
      # collect all the definitions for a particular field or group
      all_types.select { |t| include_type?(t) }.each do |type|
        type.field_prototypes.each do |prototype|
          if prototype.in_index?(self)
            field_lists[prototype.index_id(self)] << prototype.options_for_index(self)
          end
        end
      end
      # then aggregate/merge them
      fields = {}
      field_lists.each do |id, definitions|
        if definitions.length == 1
          fields[id] = definitions[0]
        else
          # if *any* of the definitions require indexing, then index
          index = definitions.map { |d| d[:index] }.any? { |i| i != false }
          fields[id] = {
            :type => String,
            :weight => definitions.map { |d| d[:weight] }.max,
            :store => true,
            :index => index
          }
          fields[id].delete(:weight) unless index
        end
      end
      fields
    end

    def include?(page)
      include_type?(page.class) and include_page?(page)
    end

    protected

    def include_type?(page_type)
      !page_type.page? or search_types.include?(page_type)
    end

    def include_page?(page)
      return true unless page.page?
      unless @exclude_pages.nil?
        rejected = @exclude_pages.any? { |selector| match_page(selector, page) }
        return false if rejected
      end
      unless @include_pages.nil?
        included = @include_pages.any? { |selector| match_page(selector, page) }
        return false if !included
      end
      true
    end

    # TODO: move this into a generic page query language class
    def match_page(selector, page)
      case selector
      when Fixnum, /\A\d+\z/
        page.id == selector.to_i
      when /\A#(.+)\z/
        page.uid == $1
      when /\A\//
        page.path == selector
      when /\A(>=|>)\s+(.+)\z/
        rule, root = $1, S::Site[$2]
        root.send(rule, page)
      else
        false
      end
    end

    def resolve_page_list(pages)
      pages.map { |p| S::Site[p] }
    end

    def base_search_types
      all_page_types
    end

    def resolve_type_list(types)
      types.map { |klass| find_type(klass) }.
        flatten
    end

    def find_type(type_definition)
      return type_definition if type_definition.is_a?(Class)
      if type_definition.is_a?(String)
        scope, base = type_definition.split(/\s+/).map { |s| s.strip }
        return scope.constantize if base.nil?
        base_type = base.constantize
        all_page_types.select { |klass| base_type.send(scope, klass) }
      end
    end

    def all_types
      S::Schema.classes
    end

    def all_page_types
      S::Schema.classes.select { |klass| klass.page? }
    end
  end # Index
end # Spontaneous
