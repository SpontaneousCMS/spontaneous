# encoding: UTF-8

module Spontaneous::Model::Core
  module SchemaId
    extend Spontaneous::Concern

    module ClassMethods
      def schema_id
        mapper.schema.to_id(self)
      end

      def schema_name
        Spontaneous::Schema.schema_name('type', nil, name)
      end

      def schema_owner
        nil
      end

      def owner_sid
        nil
      end
    end # ClassMethods

    # InstanceMethods

    SCHEMA_ID_COLUMNS = [:type, :style, :box]
    SCHEMA_ID_COLUMNS.each do |c|
      column = "#{c}_sid"
      self.class_eval(<<-RUBY, __FILE__, __LINE__)
          def #{column}
            @_#{column}_sid ||= Spontaneous.schema.uids[super]
          end

          def #{column}=(sid)
            @_#{column}_sid = Spontaneous.schema.uids[sid]
            super(@_#{column}_sid.to_s)
          end
      RUBY
    end

    def refresh
      SCHEMA_ID_COLUMNS.map { |s| "@_#{s}_sid" }.each do |s|
        remove_instance_variable(s) if instance_variable_defined?(s)
      end
      super
    end

    def schema_id
      self.class.schema_id
    end

    def schema_name
      self.class.schema_name
    end

    def schema_owner
      self.class.schema_owner
    end

    def owner_sid
      self.class.owner_sid
    end
  end # SchemaId
end
