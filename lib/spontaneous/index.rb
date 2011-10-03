# encoding: UTF-8

module Spontaneous
  class Index
    module ClassMethods
      def indexes
        @indexes ||= {}
      end

      def [](name)
        indexes[name.to_sym]
      end

      def []=(name, index)
        indexes[name.to_sym] = index
      end

      def create(name, &definition)
        index = self.new(name, &definition)
        self[name] = index
      end
    end

    extend ClassMethods

    attr_reader :name, :search_classes

    def initialize(name, &definition)
      @name = name
      @search_classes = base_search_classes
      @include_pages = nil
      @reject_pages = nil
      self.instance_eval(&definition) if definition
    end

    # Index DSL methods
    def select_pages(*page_list)
      @include_pages = page_list
    end

    def reject_pages(*page_list)
      @reject_pages = page_list
    end

    def select_classes(*classes)
      @search_classes = resolve_class_list(classes)
    end

    def reject_classes(*classes)
      @search_classes -= resolve_class_list(classes)
    end
    # end Index DSL methods

    def include?(page)
      include_class?(page.class) and include_page?(page)
    end

    protected

    def include_class?(page_class)
      search_classes.include?(page_class)
    end

    def include_page?(page)
      unless @reject_pages.nil?
        rejected = @reject_pages.any? { |selector| match_page(selector, page) }
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
        rule, root = $1, Site[$2]
        root.send(rule, page)
      else
        false
      end
    end

    def resolve_page_list(pages)
      pages.map { |p| S::Site[p] }
    end

    def base_search_classes
      all_classes
    end

    def resolve_class_list(classes)
      classes.map { |klass| find_class(klass) }.
        flatten
    end

    def find_class(class_definition)
      return class_definition if class_definition.is_a?(Class)
      if class_definition.is_a?(String)
        scope, base = class_definition.split(/\s+/).map { |s| s.strip }
        return scope.constantize if base.nil?
        base_class = base.constantize
        all_classes.select { |klass| base_class.send(scope, klass) }
      end
    end

    def all_classes
      Schema.classes.select { |klass| klass.page? }
    end
  end # Index
end # Spontaneous
