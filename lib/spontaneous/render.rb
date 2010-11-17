# encoding: UTF-8


module Spontaneous
  module Render
    class << self
      def engine_class
        @engine_class ||= Spontaneous::Cutaneous::FirstRenderEngine
      end

      def engine_class=(klass)
        @engine_class = klass
        @engine = nil
      end

      def engine
        @engine ||= engine_class.new(template_root)
      end

      def template_root
        @template_root ||= Spontaneous.template_root
      end

      def template_root=(root)
        @template_root = root
        @engine = nil
      end

      def context_helper_module
        @context_helper_module ||= Spontaneous::Cutaneous::ContextHelper
      end

      def context_helper_module=(helper_module)
        @context_helper_module = helper_module
        @context_class = nil
      end

      def context_class
        @context_class ||= Class.new.tap do |klass|
          klass.send(:include, context_helper_module)
          klass.send(:include, Context)
        end
      end

      def extension
        engine.extension
      end

      def exists?(template, format)
        File.exists?(template_file(template, format))
      end

      def template_file(template, format)
        engine.template_file(template, format)
      end

      def formats(style)
        glob = "#{engine.template_path(style.path)}.*.#{extension}"
        Dir[glob].map do |file|
          file.split('.')[-2].to_sym
        end
      end


      def render(content, format)
        context = context_class.new(content, format)
        engine.render(context.template, context)
      end
    end

    autoload :Context, "spontaneous/render/context"
  end
end
