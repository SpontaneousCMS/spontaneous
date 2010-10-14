
require File.expand_path("../../sequel/plugins/yajl_serialization", __FILE__)

module Spontaneous
  class Content < Sequel::Model(:content)
    class << self
      alias_method :sequel_plugin, :plugin
    end
    extend Plugins

    sequel_plugin :yajl_serialization, :field_store, :entry_store
    sequel_plugin :single_table_inheritance, :type_id
    sequel_plugin :instance_hooks

    plugin Plugins::Slots

    class << self
      alias_method :class_name, :name

      def class_name_with_fallback
        n = name
        if n.nil? or n.empty?
          n = "ContentClass#{object_id}"
        end
        n
      end

      def title(custom_title=nil)
        self.title = custom_title if custom_title
        @title or default_title
      end

      def default_title
        n = class_name_with_fallback.split(/::/).last.gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2')
        n.gsub!(/([a-z\d])([A-Z])/,'\1 \2')
        n
      end

      def title=(title)
        @title = title
      end

      def field(name, type=:string, options={}, &block)
        if type.is_a?(Hash)
          options = type
          type = :string
        end

        local_field_order << name
        field_prototypes[name] = FieldPrototype.new(name, type, options, &block)
        unless method_defined?(name)
          define_method(name) { fields[name] }
        else
          raise "Must give warning when field name clashes with method name"
        end

        setter = "#{name}=".to_sym
        unless method_defined?(setter)
          define_method(setter) { |value| fields[name].value = value  }
        else
          raise "Must give warning when field name clashes with method name"
        end
      end

      def field_prototypes
        @field_prototypes ||= {}
      end

      def field_names
        if @field_order && @field_order.length > 0
          remaining = default_field_order.reject { |n| @field_order.include?(n) }
          @field_order + remaining
        else
          default_field_order
        end
      end

      def default_field_order
        (supertype ? supertype.field_names : []) + local_field_order
      end

      def field_order(*new_order)
        @field_order = new_order
      end

      def local_field_order
        @local_field_order ||= []
      end

      def field?(field_name)
        field_name = field_name.to_sym
        field_prototypes.key?(field_name) || (supertype ? supertype.field?(field_name) : false)
      end

      def subclasses
        @subclasses ||= []
      end

      # supertype is like superclass but stops at the last instance of a Content class
      def supertype=(supertype)
        @supertype = supertype
      end

      def supertype
        @supertype
      end

      def descendents
        subclasses.map{ |x| [x] + x.descendents}.flatten
      end

      def inherited(subclass)
        super
        subclasses << subclass
        subclass.supertype = self
      end

      def inline_style(name, options={})
        inline_styles << Style.new(self, name, options)
      end

      def inline_styles
        @inline_styles ||= StyleDefinitions.new
      end

      alias_method :styles, :inline_styles


    end

    many_to_one :container, :class => self, :reciprocal => :nodes
    one_to_many :nodes, :key => :container_id, :class => self, :reciprocal => :container

    def after_initialize
      if new?
        self.depth = 0
        self.path = ""
        self.class.slots.instantiate(self)
      else
        self.class.slots.verify(self)
      end
      mixin_instance_code
      super
    end

    def before_create
      super
    end

    def mixin_instance_code
      self.instance_eval(self.instance_code) unless self.instance_code.nil?
    end

    def meta
      @_meta ||= \
        class << self; self; end
    end

    def field_prototypes
      self.class.field_prototypes
    end

    def fields
      @field_set ||= FieldSet.new(self, field_store)
    end

    def field?(field_name)
      self.class.field?(field_name)
    end

    # TODO: unify the update mechanism for these two stores
    def field_modified!(modified_field)
      self.field_store = @field_set.serialize
    end

    def entry_modified!(modified_entry)
      self.entries.update!
    end

    def entries
      @entries ||= EntrySet.new(self, :entry_store)
    end

    def visible_entries
      entries
    end


    def first
      entries.first
    end

    def last
      entries.last
    end


    def styles
      self.class.inline_styles
    end

    def style
      self.class.inline_styles[style_id]
    end

    def page?
      false
    end

    def push(page_or_facet)
      insert(-1, page_or_facet)
    end

    def insert(index, page_or_facet)
      save if new?
      if page_or_facet.page?
        insert_page(index, page_or_facet)
      else
        insert_facet(index, page_or_facet)
      end
    end

    alias_method :<<, :push

    def insert_page(index, child_page)
      if page
        child_page.depth = page.depth + 1
        page.children << child_page
        child_page.parent = page
        child_page.update_path
      end
      entry_style = child_page.styles.default
      entry = Entry.page(self, child_page, entry_style)
      entries.insert(index, entry)
      entry
    end

    def insert_facet(index, facet)
      facet.container = self
      facet.page = page if page
      facet.depth = depth + 1
      entry_style = facet.styles.default
      entry = Entry.facet(self, facet, entry_style)
      entries.insert(index, entry)
      entry
    end

    def page
      nil
    end

    def entry=(entry)
      @entry = entry
    end

    def entry
      @entry ||= resolve_entry
    end

    def resolve_entry
      container.entries.find { |e| e.target_id == self.id }
    end

    def render(format=:html)
      context = RenderContext.new(self, format)
      context.render
    end
  end
end
