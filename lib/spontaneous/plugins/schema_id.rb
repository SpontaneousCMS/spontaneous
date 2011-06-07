# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaId

    module ClassMethods
      def schema_id
        Spontaneous::Schema.schema_id(self)
      end

      def schema_name
        "type//#{self.name}"
      end
    end # ClassMethods

    module InstanceMethods
      [:type, :style, :box].each do |c|
        column = "#{c}_sid"
        self.class_eval(<<-RUBY)
          def #{column}
            @_#{column} ||= Spontaneous::Schema::UID[@values[:#{column}]]
          end

          def #{column}=(sid)
            @_#{column} = Spontaneous::Schema::UID[sid]
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
    end # InstanceMethods
  end # SchemaId
end



