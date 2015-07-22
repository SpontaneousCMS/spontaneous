# encoding: UTF-8

module Spontaneous::Model::Core
  module Serialisation
    extend Spontaneous::Concern

    module ClassMethods
      def export(user = nil)
        {
          type: ui_class,
          id: schema_id.to_s,
          is_page: page?,
          is_alias: alias?,
          title: title,
          fields: readable_fields(user).map { |name| field_prototypes[name].export(user) },
          styles: readable_styles(user).map { |style| style.export(user) },
          boxes: readable_boxes(user).map { |box| box.export(user) },
          source: __source_file
        }
      end

      def readable_styles(user)
        styles
      end

      def readable_boxes(user)
        boxes.select { |box| box.readable?(user) }
      end

      def readable_fields(user)
        field_names.select { |name| field_readable?(user, name) }
      end

      def serialise_http(user = nil)
        Spontaneous.serialise_http(export(user))
      end

    end # ClassMethods

    # InstanceMethods

    def core_shallow_export(user)
      { id: id,
        type: model.ui_class,
        type_id: model.schema_id.to_s,
        is_page: page?,
        page_id: page_id || id,
        hidden: (hidden? ? true : false),
        depth: content_depth,
        fields: fields.export(user),
        label: label }
    end

    def shallow_export(user)
      core_shallow_export(user)
    end

    # Defines the values that are exported to the interface when this content
    # item is being referenced as an alias to the item being viewed.
    def alias_export(user)
      core_shallow_export(user).merge({
        title: title,
        path: page.path,
        box: box.alias_export(user)
      })
    end

    def export(user = nil)
      shallow_export(user).merge({
        aliases: aliases.map { |a| a.alias_export(user) },
        boxes: self.class.readable_boxes(user).map { |box| boxes[box.name].export(user) }
      })
    end


    def serialise_http(user = nil)
      Spontaneous.serialise_http(export(user))
    end
  end # Serialisation
end # Spontaneous::Plugins
