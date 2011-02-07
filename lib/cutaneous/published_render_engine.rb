# encoding: UTF-8

module Cutaneous
  class FromPublishedTemplate < SecondRenderEngine
    def initialize
      @context_class = RequestContext
    end

    def path_for_content(context)
      path = Spontaneous::Render.output_path(revision, context, context.format, self.extension)
    end

    def get_template(filepath, format)
      template = create_template(filepath, format)
    end

    def revision
      Spontaneous::Site.published_revision
    end
  end

  class PublishedRenderEngine < RenderEngine

    def render_engine
      @render_engine ||= FromPublishedTemplate.new
    end

    def revision
      Spontaneous::Site.published_revision
    end

    def render_content(page, format=:html, params={})
      # in production env static files are handled by web server
      if Spontaneous.development? or Spontaneous.test?
        path = Spontaneous::Render.output_path(revision, page, format)
        if ::File.exists?(path)
          puts "returning #{path}"
          return ::File.read(path)
        end
      end
      path = Spontaneous::Render.output_path(revision, page, format, render_engine.extension)
      puts path
      if Spontaneous.development? or Spontaneous.test? or !::File.exists?(path)
        puts "rendering #{page.path}"
        S::Render.with_publishing_engine do
          S::Render.render_page(revision, page, format)
        end
      end
      render_engine.render_content(page, format, params)
    end
  end
end

