# encoding: UTF-8


module Spontaneous
  module Render
    def self.output_path(revision, page, format, extension = nil)
      ext = ".#{format}"
      ext += ".#{extension}" if extension

      dir = revision_root(revision) / format / page.path
      path = dir / "/index#{ext}"
      path
    end


    def self.revision_root(revision)
      S::Site.revision_dir(revision)
    end

    class << self
      def render_pages(revision, pages, format, progress=nil)
        klass = Format.const_get("#{format.to_s.camelize}")
        renderer = klass.new(revision, pages, progress)
        renderer.render
      end

      def render_page(revision, page, format, progress=nil)
        render_pages(revision, [page], format, progress)
      end

      def renderer_class
        @renderer_class ||= PublishedRenderer
      end

      def renderer_class=(klass)
        @renderer_class = klass
        @renderer = nil
      end

      def renderer
        @renderer ||= renderer_class.new(template_root)
      end

      def with_preview_renderer(&block)
        with_renderer(PreviewRenderer, &block)
      end

      def with_publishing_renderer(&block)
        with_renderer(PublishingRenderer, &block)
      end

      def with_published_renderer(&block)
        with_renderer(PublishedRenderer, &block)
      end

      @@renderer_stack = []

      def with_renderer(new_renderer, &block)
        @@renderer_stack.push(self.renderer_class)
        self.renderer_class = new_renderer
        yield if block_given?
      ensure
        self.renderer_class = @@renderer_stack.pop
      end


      def template_root
        @template_root ||= Spontaneous.root / "templates"
      end

      def template_path(*path)
        ::File.join(template_root, *path)
      end

      def template_root=(root)
        @template_root = root
        @renderer = nil
      end

      def extension
        Spontaneous.template_ext
      end

      def exists?(template_root, template, format)
        File.exists?(template_file(template_root, template, format))
      end

      def template_file(template_root, filename, format)
        ::File.join(template_root, template_name(filename, format))
      end

      def template_name(filename, format)
        "#{filename}.#{format}.#{Spontaneous.template_ext}"
      end



      def formats(style)
        glob = "#{template_path(style.path)}.*.#{extension}"
        Dir[glob].map do |file|
          file.split('.')[-2].to_sym
        end
      end

      def render(content, format=:html, params={})
        Content.with_visible do
          renderer.render_content(content, format || :html, params)
        end
      end
    end
    autoload :Engine, "spontaneous/render/engine"

    autoload :Context, "spontaneous/render/context"

    autoload :Renderer, "spontaneous/render/renderer"
    autoload :PreviewRenderer, "spontaneous/render/preview_renderer"
    autoload :PublishingRenderer, "spontaneous/render/publishing_renderer"
    autoload :PublishedRenderer, "spontaneous/render/published_renderer"

    autoload :Format, "spontaneous/render/format"
  end
end
