# encoding: UTF-8


class Spontaneous::Site
  module Features
    extend Spontaneous::Concern

    # InstanceMethods
    def back_controllers
      @back_controllers ||= []
    end

    def front_controllers
      @front_controllers ||= []
    end

    def register_back_controller(namespace, controller_class)
      app = Spontaneous::Rack.make_back_controller(controller_class)
      back_controllers << [namespace_url(namespace), app]
    end

    def register_front_controller(namespace, controller_class)
      app = Spontaneous::Rack.make_front_controller(controller_class)
      front_controllers << [namespace_url(namespace), app]
    end

    def namespace_url(namespace)
      "/@#{namespace}"
    end
  end # Features
end
