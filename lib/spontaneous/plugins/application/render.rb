# encoding: UTF-8

require 'cutaneous'

module Spontaneous::Plugins::Application
  module Render
    extend Spontaneous::Concern

    module ClassMethods
      attr_accessor :render_engine

      def template_ext
        template_engine.extension
      end

      def template_engine
        @template_engine ||= Cutaneous
      end

      def template_engine=(engine)
        @template_engine = engine
      end
    end # ClassMethods
  end # Render
end # Spontaneous::Plugins::Application
