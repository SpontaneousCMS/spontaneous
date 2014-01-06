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
    def register_back_controller(namespace, app, opts = {})
      app = Spontaneous::Rack.make_back_controller(app)
      path_prefix = opts.fetch(:path_prefix, namespace_url(namespace))
      back_controllers << [path_prefix, app]
    end

    def register_front_controller(namespace, app, opts = {})
      app = Spontaneous::Rack.make_front_controller(app)
      path_prefix = opts.fetch(:path_prefix, namespace_url(namespace))
      front_controllers << [path_prefix, app]
    end

    def namespace_url(namespace)
      "/@#{namespace}"
    end
  end # Features
end
