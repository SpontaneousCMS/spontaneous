# encoding: UTF-8

module Spontaneous::Plugins::Application
  module Features
    extend Spontaneous::Concern

    module ClassMethods
      def register_back_controller(namespace, controller_class, opts = {})
        instance.register_back_controller(namespace, controller_class, opts)
      end

      def register_front_controller(namespace, controller_class, opts = {})
        instance.register_front_controller(namespace, controller_class, opts)
      end

      def front
        instance.front
      end
    end # ClassMethods
  end # Features
end
