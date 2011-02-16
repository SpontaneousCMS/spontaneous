# encoding: UTF-8


module Spontaneous::Plugins
  module Permissions

    module ClassMethods
      def box_readable?(box_name)
        box_permission(box_name, :read_level)
      end
      def box_writable?(box_name)
        box_permission(box_name, :write_level)
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

      def box_permission(box_name, test)
        return true unless user = Spontaneous::Permissions.active_user
        if box = boxes[box_name]
          user.level >= box.__send__(test)
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

      def box_writable?(box_name)
        self.class.box_writable?(box_name)
      end

      def box_readable?(box_name)
        self.class.box_readable?(box_name)
      end
    end # InstanceMethods

  end # Permissions
end # Spontaneous::Plugins

