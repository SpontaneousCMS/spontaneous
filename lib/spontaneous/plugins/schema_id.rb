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

      # In the case where a new class has been added to the schema
      # the STI values have been set up on a class whose schema id is undefined
      # so we need to correct this once a new ID has been generated
      # Bit dodgy, what I should do instead is rewrite the STI code to always defer
      # to the schema for its values
      def update_schema_id(new_id)
        sti_key_array << new_id.to_s
        superclass.sti_subclass_added(new_id.to_s, self) if superclass
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
