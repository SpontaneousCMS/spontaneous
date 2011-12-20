# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaId
    extend ActiveSupport::Concern

    module ClassMethods
      def schema_id
        Spontaneous.instance.schema_id(self)
      end

      def schema_name
        "type//#{self.name}"
      end

      def schema_owner
        nil
      end

      def owner_sid
        nil
      end
    end # ClassMethods

    # InstanceMethods

    [:type, :style, :box].each do |c|
      column = "#{c}_sid"
      self.class_eval(<<-RUBY)
          def #{column}
            @_#{column} ||= Spontaneous.schema.uids[@values[:#{column}]]
          end

          def #{column}=(sid)
            @_#{column} = Spontaneous.schema.uids[sid]
            @values[:#{column}] = @_#{column}.to_s
            @_#{column}
          end
      RUBY
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
