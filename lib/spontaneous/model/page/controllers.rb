# encoding: UTF-8

module Spontaneous::Model::Page
  module Controllers
    extend Spontaneous::Concern

    ACTION_SEPARATOR = "@".freeze

    module ClassMethods
      def controllers
        @controllers ||= Spontaneous::Collections::PrototypeSet.new(supertype, :controllers)
      end

      def controller_base_class
        return ::PageController if defined?(::PageController)
        default_controller_base_class
      end

      def default_controller_base_class
        Spontaneous::Rack::PageController
      end

      def controller(namespace, base_class = controller_base_class, &block)
        controller_class_name = "#{namespace.to_s.camelize}Controller"
        controller_class = Class.new(base_class)
        controller_class.class_eval(&block) if block_given?
        self.const_set(controller_class_name, controller_class) unless self.const_defined?(controller_class_name)
        controllers[namespace.to_sym] = controller_class
      end
    end # ClassMethods

    # InstanceMethods

    # resolve and call the relevant action handler and return the results to the controller
    def process_action(action_path, env, format)
      env = env.dup
      namespace, *p = action_path.split(S::Constants::SLASH)
      path = [S::Constants::EMPTY].concat(p).join(S::Constants::SLASH)
      env[S::Constants::PATH_INFO] = path
      controller_class = self.class.controllers[namespace.to_sym]
      return 404 unless controller_class
      app = controller_class.new(self, format)
      app.call(env)
    end

    # generate an action URL of the form
    # <path to page>/@<action namespace>/<action path>
    def action_url(namespace, path)
      [self.path, "#{ACTION_SEPARATOR}#{namespace}", path].join(S::Constants::SLASH).gsub(%r{//}, '/')
    end
  end # Controllers
end
