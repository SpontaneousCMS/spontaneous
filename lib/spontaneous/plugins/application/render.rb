# encoding: UTF-8


module Spontaneous::Plugins::Application
  module Render

    def self.configure(base)
    end

    module ClassMethods
      attr_accessor :render_engine

      def template_ext
        Cutaneous.extension
      end
    end # ClassMethods
  end # Render
end

