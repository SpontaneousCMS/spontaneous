# encoding: UTF-8

require 'forwardable'
module Spontaneous
  module Errors
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

  end
  class SchemaModificationError < Errors::Error
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
