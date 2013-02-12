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
      @stemmer = @stopper = nil
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

    def language(set_language = nil)
      @language = set_language unless set_language.nil?
      @language ||= :english
    end

    def stemmer(set_stemmer = nil)
      @stemmer = set_stemmer unless set_stemmer.nil?
      @stemmer
    end

    def stopper(set_stopper = nil)
      @stopper = set_stopper unless set_stopper.nil?
      @stopper
    end

    def weights(page)
      weights = {}
      each_field(page) do |field, prototype, id|
        weights[id] = prototype.options_for_index(self)[:weight]
      end
      weights
    end

    # Extract all indexable content from a page. Values are grouped across fields
    # or across field index groups
    def indexable_content(page)
      values = Hash.new { |h, k| h[k] = [] }
      each_indexable(page) do |content|
        content.fields.each do |field|
          prototype = field.prototype
          if prototype.in_index?(self)
            values[prototype.index_id(self)] << field.indexable_value
          end
        end
        insert_additional_indexable_values(content, values)
      end
      result = Hash[ values.map { |id, values| [id, values.join("\n")] } ]
      result[:id] = page.id
      result
    end

    def each_indexable(page)
      indexable = [page]
      # not sure that I need the include? test here as page.content only returns Pieces
      # and I'm not sure that there is a particular need to exclude Pieces from indexes
      indexable.concat(page.pieces.select { |content| include?(content) })
      indexable += page.boxes.select { |box| include?(box) }
      indexable.each do |content|
        yield content
      end
    end

    def each_field(page)
      each_indexable(page) do |content|
        content.fields.each do |field|
          prototype = field.prototype
          if prototype.in_index?(self)
            yield field, prototype, prototype.index_id(self)
          end
        end
      end
    end

    def insert_additional_indexable_values(content, values)
      if content.respond_to?(:additional_search_values)
        add = content.additional_search_values
        case add
        when Array
          add.each do |row|
            row.each { |k, v| values[k.to_s] << v }
          end
        when Hash
          add.each { |k, v| values[k.to_s] << v }
        end
      end
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

    def include?(content)
      include_type?(content.class) and include_page?(content.page)
    end

  protected

    def include_type?(type)
      search_types.include?(type)
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
      all_types
    end

    def resolve_type_list(types)
      types.map { |klass| find_type(klass) }.flatten
    end

    def find_type(type_definition)
      return type_definition if type_definition.is_a?(Class)
      type_definition = type_definition.to_s if Symbol === type_definition
      if type_definition.is_a?(String)
        scope, base = type_definition.split(/\s+/).map { |s| s.strip }
        return scope.constantize if base.nil?
        base_type = base.constantize
        all_types.select { |klass| base_type.send(scope, klass) }
      end
    end

    def all_types
      S.schema.classes
    end

    def all_page_types
      S.schema.classes.select { |klass| klass.page? }
    end
  end # Index
end # Spontaneous
