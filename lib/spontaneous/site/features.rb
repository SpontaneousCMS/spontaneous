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

    # Mounts an app into the authenticated CMS application
    #   namespace: the namespace of the app. A namespace of `moderation` will be mounted
    #              inside the CMS as /@moderation
    #   app: A Rack compatible class or Proc
    def register_back_controller(namespace, app)
      app = Spontaneous::Rack.make_back_controller(app)
      back_controllers << [namespace_url(namespace), app]
    end

    def register_front_controller(namespace, app)
      app = Spontaneous::Rack.make_front_controller(app)
      front_controllers << [namespace_url(namespace), app]
    end

    def namespace_url(namespace)
      "/@#{namespace}"
    end
  end # Features
end
