
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
  autoload :FieldPrototype, "spontaneous/field_prototype"
  autoload :Field, "spontaneous/field"
  autoload :FieldTypes, "spontaneous/field_types"
  autoload :FieldSet, "spontaneous/field_set"
  autoload :Entry, "spontaneous/entry"
  autoload :PageEntry, "spontaneous/page_entry"
  autoload :EntrySet, "spontaneous/entry_set"
  autoload :Page, "spontaneous/page"
  autoload :Facet, "spontaneous/facet"
  autoload :Style, "spontaneous/style"
  autoload :StyleDefinitions, "spontaneous/style_definitions"
  autoload :Slot, "spontaneous/slot"
  autoload :SlotDefinitions, "spontaneous/slot_definitions"
  autoload :SlotProxy, "spontaneous/slot_proxy"
  autoload :Template, "spontaneous/template"
  autoload :RenderContext, "spontaneous/render_context"
  autoload :RenderFormatProxy, "spontaneous/render_format_proxy"

  module TemplateTypes
    autoload :ErubisTemplate, "spontaneous/template_types/erubis_template"
  end

  module Plugins
    autoload :Slots, "spontaneous/plugins/slots"
  end
end

