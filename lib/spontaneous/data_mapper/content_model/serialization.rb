module Spontaneous::DataMapper
  module ContentModel
    module Serialization
      def self.included(model)
        # Don't want to pollute this shared module with the accessors
        # (in case we are using this in multiple models)
        m = Module.new
        model.serialized_columns.each do |column|
          m.module_eval (<<-RB), __FILE__, __LINE__
            def #{column}
              _deserialize_column(:#{column}) { super }
            end
            def #{column}=(value)
              super(_serialize_column(:#{column}, value))
            end
          RB
        end
        model.send :include, m
      end

      def refresh
        _deserialized_values.clear
        super
      end

      private

      def _deserialized_values
        @_deserialized_values ||= {}
      end

      def _deserialize_column(column)
        cache = _deserialized_values
        unless cache.key?(column)
          cache[column] = _deserialize_value(yield)
        end
        cache[column]
      end

      def _deserialize_value(value)
        Spontaneous::parse_json(value || "null")
      end

      def _serialize_column(column, value)
        _deserialized_values[column] = value
        _serialize_value(value)
      end

      def _serialize_value(value)
        Spontaneous::encode_json(value)
      end
    end
  end
end
