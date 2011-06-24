# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Plugins
  module Actions

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
    end # InstanceMethods
  end # Actions
end
