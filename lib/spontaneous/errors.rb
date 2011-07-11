# encoding: UTF-8

require 'forwardable'
module Spontaneous
  class Error < StandardError; end

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


  class UnknownFormatException < Error
    def initialize(unsupported_format)
      super("Format '#{unsupported_format}' has no matching mime type")
    end
  end
  class UnsupportedFormatException < Error
    def initialize(style, unsupported_format)
      super("'#{unsupported_format}' format not supported by style '#{style.name}'.\nTemplate path: #{style.directory}\n")
    end
  end

  class SchemaModificationError < Error
    extend Forwardable

    attr_reader :modification

    def initialize(modification)
      @modification = modification
    end

    def_delegators :@modification, :added_classes, :removed_classes
    def_delegators :@modification, :added_fields, :removed_fields
    def_delegators :@modification, :added_boxes, :removed_boxes
    def_delegators :@modification, :added_styles, :removed_styles
    def_delegators :@modification, :added_layouts, :removed_layouts
  end
end
