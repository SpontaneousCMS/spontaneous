# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Plugins
  module Actions
    ACTION_SEPARATOR = "@".freeze

    class ActionHandler < Sinatra::Base
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
      def action_handlers
        @action_handlers ||= {}
      end

      def actions(namespace, &block)
        actions_class = Class.new(ActionHandler)
        actions_class.class_eval(&block) if block_given?
        self.const_set("#{namespace.to_s.camelize}Actions", actions_class)
        action_handlers[namespace.to_sym] = actions_class
      end
    end # ClassMethods

    module InstanceMethods
      # resolve and call the relevant action handler and return the results to the controller
      def process_action(action_path, env, format)
        env = env.dup
        namespace, *p = action_path.split(S::Constants::SLASH)
        path = [S::Constants::EMPTY].concat(p).join(S::Constants::SLASH)
        env[S::Constants::PATH_INFO] = path
        klass = self.class.action_handlers[namespace.to_sym]
        return 404 unless klass
        app = klass.new(self, format)
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
