
Sequel.extension :inflector

module Spontaneous
  SLASH = "/".freeze
  class << self
    def template_root=(template_root)
      @template_root = template_root
    end

    def template_root
      @template_root ||= File.expand_path(File.join(File.dirname(__FILE__), "../templates"))
    end

    def template_ext
      "erb"
    end
  end

  autoload :ProxyObject, "spontaneous/proxy_object"
  autoload :Plugins, "spontaneous/plugins"

  autoload :Content, "spontaneous/content"
  autoload :Page, "spontaneous/page"
  autoload :Facet, "spontaneous/facet"

  autoload :FieldTypes, "spontaneous/field_types"

  autoload :Entry, "spontaneous/entry"
  autoload :PageEntry, "spontaneous/page_entry"
  autoload :EntrySet, "spontaneous/entry_set"


  autoload :Style, "spontaneous/style"
  autoload :StyleDefinitions, "spontaneous/style_definitions"
  autoload :Template, "spontaneous/template"
  autoload :RenderContext, "spontaneous/render_context"
  autoload :RenderFormatProxy, "spontaneous/render_format_proxy"

  module TemplateTypes
    autoload :ErubisTemplate, "spontaneous/template_types/erubis_template"
  end

  module Plugins
    autoload :Slots, "spontaneous/plugins/slots"
    autoload :Fields, "spontaneous/plugins/fields"
    autoload :Entries, "spontaneous/plugins/entries"
    autoload :Styles, "spontaneous/plugins/styles"
    autoload :SchemaTitle, "spontaneous/plugins/schema_title"
    autoload :Render, "spontaneous/plugins/render"
    autoload :SchemaHierarchy, "spontaneous/plugins/schema_hierarchy"
    autoload :InstanceCode, "spontaneous/plugins/instance_code"
    autoload :PageStyles, "spontaneous/plugins/page_styles"
    autoload :Paths, "spontaneous/plugins/paths"
    autoload :PageTree, "spontaneous/plugins/page_tree"
    autoload :AllowedTypes, "spontaneous/plugins/allowed_types"

    module Slots
      autoload :SlotDefinitions, "spontaneous/plugins/slots/slot_definitions"
      autoload :SlotSet, "spontaneous/plugins/slots/slot_set"
      autoload :Slot, "spontaneous/plugins/slots/slot"
    end

    module Fields
      autoload :FieldPrototype, "spontaneous/plugins/fields/field_prototype"
      autoload :FieldSet, "spontaneous/plugins/fields/field_set"
    end
  end


  class UnknownTypeException < Exception
    def initialize(parent, type)
      super("Unknown content type '#{type}' requested in class #{parent}")
    end
  end
  class UnknownStyleException < Exception
    def initialize(style_name, klass)
      super("Unknown style '#{style_name}' for class #{klass}")
    end
  end

end

