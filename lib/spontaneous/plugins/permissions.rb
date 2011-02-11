# encoding: UTF-8


module Spontaneous::Plugins
  module Permissions

    module ClassMethods
      def slot_readable?(slot_name)
        slot_permission(slot_name, :read_level)
      end
      def slot_writable?(slot_name)
        slot_permission(slot_name, :write_level)
      end

      def field_readable?(field_name)
        field_permission(field_name, :read_level)
      end

      def field_writable?(field_name)
        field_permission(field_name, :write_level)
      end

      def field_permission(field_name, test)
        return true unless user = Spontaneous::Permissions.active_user
        if field = field_prototypes[field_name]
          user.level >= field.__send__(test)
        else
          nil # or perhaps throw error
        end
      end

      def slot_permission(slot_name, test)
        return true unless user = Spontaneous::Permissions.active_user
        if slot = slots[slot_name]
          user.level >= slot.__send__(test)
        else
          nil # or perhaps throw error
        end
      end
    end # ClassMethods


    module InstanceMethods
      def field_readable?(field_name)
        self.class.field_readable?(field_name)
      end

      def field_writable?(field_name)
        self.class.field_writable?(field_name)
      end

      def slot_writable?(slot_name)
        self.class.slot_writable?(slot_name)
      end
      def slot_readable?(slot_name)
        self.class.slot_readable?(slot_name)
      end
    end # InstanceMethods

  end # Permissions
end # Spontaneous::Plugins

