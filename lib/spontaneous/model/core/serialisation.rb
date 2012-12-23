# encoding: UTF-8

module Spontaneous::Model::Core
  module Serialisation
    extend Spontaneous::Concern

    module ClassMethods
      def export(user = nil)
        {
          :type=> self.ui_class,
          :id => self.schema_id.to_s,
          :is_page => self.page?,
          :is_alias => self.alias?,
          :title=> self.title,
          :fields => readable_fields(user).map { |name| field_prototypes[name].export(user) },
          :styles => readable_styles(user).map { |style| style.export(user) },
          :boxes => readable_boxes(user).map { |box| box.export(user) },
          :source => self.__source_file
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

    def shallow_export(user)
      { :id => id,
        :type => self.class.ui_class,
        :type_id => self.class.schema_id.to_s,
        :is_page => page?,
        :hidden => (hidden? ? true : false),
        :depth => content_depth,
        :fields  => fields.export(user),
        :label => label }
    end

    def export(user = nil)
      shallow_export(user).merge({
        :boxes => self.class.readable_boxes(user).map { |box| boxes[box.name].export(user) }
      })
    end


    def serialise_http(user = nil)
      Spontaneous.serialise_http(export(user))
    end
  end # Serialisation
end # Spontaneous::Plugins
