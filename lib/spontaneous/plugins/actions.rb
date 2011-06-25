# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Plugins
  module Actions
    ACTION_SEPARATOR = "@".freeze

    class Controller < Sinatra::Base
      attr_reader :content, :format

      def initialize(content, format)
        @content, @format = content, (format || :html).to_sym
        super(nil)
      end

      def page
        content.page
      end
    end

    module ClassMethods
      def controllers
        if (supertype? and supertype.respond_to?(:controllers))
          supertype.controllers.dup.merge(local_controllers)
        else
          local_controllers
        end
      end

      def local_controllers
        @controllers ||= {}
      end

      def controller(namespace, &block)
        controller_class = Class.new(Controller)
        controller_class.class_eval(&block) if block_given?
        self.const_set("#{namespace.to_s.camelize}Controller", controller_class)
        local_controllers[namespace.to_sym] = controller_class
      end
    end # ClassMethods

    module InstanceMethods
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
    end # InstanceMethods
  end # Actions
end
