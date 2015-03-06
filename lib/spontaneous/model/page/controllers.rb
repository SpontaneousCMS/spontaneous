# encoding: UTF-8

module Spontaneous::Model::Page
  module Controllers
    extend Spontaneous::Concern

    ACTION_SEPARATOR = "@".freeze

    module ClassMethods
      def controllers
        @controllers ||= Spontaneous::Collections::PrototypeSet.new(supertype, :controllers)
      end

      def default_controller_base_class
        return ::PageController if defined?(::PageController)
        Spontaneous::Rack::PageController
      end

      # Searches through the type heirarchy for the first defined controller
      # if there isn't one for the given namespace it tries on the 'default'
      # namespace
      def controller_superclass(namespace, base_class)
        return base_class unless base_class.nil?
        search = ancestors.select { |klass| klass.respond_to?(:controllers) }
        controller_superclass = [namespace, :__nil__].uniq.flat_map { |n|
          search.map { |type| type.controllers[n] }
        }.compact.first
        controller_superclass ||= default_controller_base_class
      end

      def controller(namespace = :__nil__, base_class = nil, &block)
        namespace_name = (namespace == :__nil__ ? "Root" : namespace.to_s.camelize)
        controller_class = Class.new(controller_superclass(namespace, base_class))
        const_set("#{namespace_name}Controller", controller_class)# unless self.const_defined?(controller_class_name)
        controller_class.class_eval(&block) if block_given?
        controllers[namespace] = controller_class
      end

      METHOD_MAP = Hash[%w(GET PUT POST DELETE HEAD OPTIONS PATCH LINK UNLINK).map { |m| [m, m.downcase.to_sym] }].freeze

      def normalize_method(method)
        return method if method.is_a?(Symbol)
        METHOD_MAP[method]
      end

      # Tests for existance of a request handler for a method
      # Used by the publishing mechanism to determine which template bucket a
      # published page should be placed in.
      def dynamic?(method = :get)
        method = normalize_method(method)
        return true unless method == :get
        controller = controllers[:__nil__]
        controller and controller.dynamic?(method)
      end
    end # ClassMethods

    # InstanceMethods

    def dynamic?(method = :get)
      self.class.dynamic?(method)
    end

    # resolve and call the relevant action handler and return the results to the controller
    def process_action(site, action_path, env, format)
      namespace, *parts = action_path.split(S::Constants::SLASH)
      path = "/" << parts.join(S::Constants::SLASH)
      env[S::Constants::PATH_INFO] = path
      run_controller(site, namespace, env, format)
    end

    def process_root_action(site, env, format)
      run_controller(site, :__nil__, env, format)
    end

    def run_controller(site, namespace, env, format)
      controller_class = self.class.controllers[namespace.to_sym]
      return 404 if controller_class.nil?
      app = controller_class.new(site, self, format)
      status, headers, body = app.call(env)
      [status, headers, body]
    end

    # generate an action URL of the form
    # <path to page>/@<action namespace>/<action path>
    def action_url(namespace, path = nil)
      [self.path, "#{ACTION_SEPARATOR}#{namespace}", path].compact.join(S::Constants::SLASH).gsub(%r{//}, '/')
    end
  end # Controllers
end
