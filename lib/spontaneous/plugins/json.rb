# encoding: UTF-8


module Spontaneous::Plugins
  module JSON

    module ClassMethods
      def to_hash
        {
          :type=> self.json_name,
          :title=> self.title,
          :fields => readable_fields.map { |name| field_prototypes[name].to_hash },
          :allowed_types => allowed_types.map { |type| type.instance_class.json_name }
        }
      end

      def readable_fields
        field_names.select { |name| field_readable?(name) }
      end

      def to_json
        to_hash.to_json
      end

    end # ClassMethods

    module InstanceMethods
      def to_shallow_hash
        {
          :id => id,
          :type => self.class.json_name,
          # :type_id => type.id,
          :is_page => page?,
          :depth => depth,
          :fields  => fields.to_hash,
          :name => slot_name,
          :label => label
        }
      end

      def to_hash
        to_shallow_hash.merge({
          :entries => (slots.empty? ? entries : slots).to_hash
        })
      end


      def to_json
        to_hash.to_json
      end
    end # InstanceMethods
  end # JSON
end # Spontaneous::Plugins

