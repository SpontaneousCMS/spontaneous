# encoding: UTF-8

module Spontaneous::Plugins::Application
  module Features
    extend ActiveSupport::Concern

    module ClassMethods
      def register_back_controller(namespace, controller_class)
        instance.register_back_controller(namespace, controller_class)
      end

      def register_front_controller(namespace, controller_class)
        instance.register_front_controller(namespace, controller_class)
      end
    end # ClassMethods
  end # Features
end
