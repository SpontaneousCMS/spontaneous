# encoding: UTF-8


module Spontaneous
  module Render
    class << self
      def render_pages(revision, pages, format, progress=nil)
        klass = Format.const_get("#{format.to_s.camelize}")
        renderer = klass.new(revision, pages, progress)
        renderer.render
      end

      def engine_class
        @engine_class ||= Cutaneous::FirstRenderEngine
      end

      def engine_class=(klass)
        @engine_class = klass
        @engine = nil
      end

      def engine
        @engine ||= engine_class.new(template_root)
      end

      def with_publishing_engine(&block)
        with_engine(Cutaneous::PublishRenderEngine, &block)
      end

      @@engine_stack = []

      def with_engine(new_engine_class, &block)
        @@engine_stack.push(self.engine_class)
        self.engine_class = new_engine_class
        yield if block_given?
      ensure
        self.engine_class = @@engine_stack.pop
      end


      def template_root
        @template_root ||= Spontaneous.root / "templates"
      end

      def template_root=(root)
        @template_root = root
        @engine = nil
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

      def render(content, format=:html, params={})
        engine.render_content(content, format, params)
      end
    end

    autoload :Context, "spontaneous/render/context"
    autoload :Engine, "spontaneous/render/engine"
    autoload :Format, "spontaneous/render/format"
  end
end
