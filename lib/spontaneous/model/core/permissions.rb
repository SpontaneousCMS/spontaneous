# encoding: UTF-8

module Spontaneous::Model::Core
  module Permissions
    extend Spontaneous::Concern

    module ClassMethods
      def box_readable?(user, box_name)
        box_permission(user, box_name, :read_level)
      end
      def box_writable?(user, box_name)
        box_permission(user, box_name, :write_level)
      end

      def field_readable?(user, field_name)
        field_permission(user, field_name, :read_level)
      end

      def field_writable?(user, field_name)
        field_permission(user, field_name, :write_level)
      end

      def field_permission(user, field_name, test)
        return true unless user
        if field = field_prototypes[field_name.to_sym]
          user.level >= field.__send__(test)
        else
          nil # or perhaps throw error
        end
      end

      def box_permission(user, box_name, test)
        return true unless user
        if box = boxes[box_name.to_sym]
          user.level >= box.__send__(test)
        else
          nil # or perhaps throw error
        end
      end
    end # ClassMethods


    # InstanceMethods

    def field_readable?(user, field_name)
      self.class.field_readable?(user, field_name)
    end

    def field_writable?(user, field_name)
      self.class.field_writable?(user, field_name)
    end

    def box_writable?(user, box_name)
      self.class.box_writable?(user, box_name)
    end

    def box_readable?(user, box_name)
      self.class.box_readable?(user, box_name)
    end
  end # Permissions
end # Spontaneous::Plugins
