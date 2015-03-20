# encoding: UTF-8

require "forwardable"

module Spontaneous
  class Error < StandardError; end

  class UnknownTypeException < Error
    def initialize(parent, type)
      super("Unknown content type '#{type}' requested in class #{parent}")
    end
  end

  class UnknownStyleException < Error
    def initialize(style_name, klass)
      super("Unknown style '#{style_name}' for class #{klass}")
    end
  end

  # raised when trying to show something that is not showable due to
  # ancestor being hidden
  class NotShowable < Error
    def initialize(content, hidden_ancestor_id)
      @content, @hidden_ancestor_id = content, hidden_ancestor_id
    end
  end

  class UnknownLayoutError < Error
    def initialize(parent_class, layout_name)
      @parent_class, @layout_name = parent_class, layout_name
    end
  end


  class UnknownOutputException < Error
    def initialize(content_class, unsupported_output_name)
      super("Type '#{content_class}' does not output '#{unsupported_output_name}'")
    end
  end

  class UnsupportedFormatException < Error
    def initialize(style, unsupported_format)
      super("'#{unsupported_format}' format not supported by style '#{style.name}'.\nTemplate path: #{style.directory}\n")
    end
  end

  class InvalidPrototypeDefinitionError < Error; end

  class AnonymousRootException < Error
    def initialize
      super("Content roots must have a valid slug")
    end
  end

  class SingletonException < Error
    def initialize(type)
      super("Attempt to create a second instance of #{type}")
    end
  end

  class SchemaModificationError < Error
    extend Forwardable

    attr_reader :modification

    def initialize(modification)
      @modification = modification
    end

    def_delegators :@modification, :added_classes, :removed_classes
    def_delegators :@modification, :added_fields,  :removed_fields
    def_delegators :@modification, :added_boxes,   :removed_boxes
    def_delegators :@modification, :added_styles,  :removed_styles
    def_delegators :@modification, :added_layouts, :removed_layouts
  end

  class ReadOnlyScopeModificationError < Error
    def initialize(box)
      super("Attempt to modify the contents of box #{box.inspect} within a read-only scope")
    end
  end
end
