module Sequel
  module Plugins
    SID = Spontaneous::Schema::UID

    module SchemaUid
      def self.configure(model, *columns)
        model.schema_uid_columns(*columns) unless columns.empty?
      end

      module ClassMethods
        attr_accessor :serialization_module

        def schema_uid_columns(*columns)
          m = self
          include(self.serialization_module ||= Module.new) unless serialization_module
          serialization_module.class_eval do
            columns.each do |column|
              define_method(column) do
                if deserialized_sids.has_key?(column)
                  deserialized_sids[column]
                else
                  deserialized_sids[column] = deserialize_sid(column, super())
                end
              end
              define_method("#{column}=") do |v|
                changed_columns << column unless changed_columns.include?(column)
                deserialized_sids[column] = deserialize_sid(column, v)
                @values[column] = serialize_sid(column, v)
              end
            end
          end
        end
      end

      module InstanceMethods
        attr_reader :deserialized_sids

        def initialize(*args)
          @deserialized_sids = {}
          super
        end

        private

        def serialize_sid(column, value)
          value.to_s
        end

        def deserialize_sid(column, value)
          SID[value]
        end
      end
    end
  end
end
