# encoding: UTF-8


module Spontaneous::Plugins::Site
  module Features
    module InstanceMethods

      def back_controllers
        @back_controllers ||= []
      end

      def front_controllers
        @front_controllers ||= []
      end

      def register_back_controller(namespace, controller_class)
        Spontaneous::Rack.make_back_controller(controller_class)
        controller_class.requires_authentication!
        back_controllers << [namespace_url(namespace), controller_class]
      end

      def register_front_controller(namespace, controller_class)
        Spontaneous::Rack.make_front_controller(controller_class)
        front_controllers << [namespace_url(namespace), controller_class]
      end

      def namespace_url(namespace)
        "/@#{namespace}"
      end
    end # ClassMethods
  end # Features
end

