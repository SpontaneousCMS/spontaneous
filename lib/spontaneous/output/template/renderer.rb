
module Spontaneous::Output::Template
  # Renderers are responsible for creating contexts from objects & passing these
  # onto the right template engine
  # You only have one renderer instance per spontaneous role:
  #
  #   - editing/previewing : PreviewRenderer
  #   - publishing         : PublishRenderer
  #   - the live site      : PublishedRenderer
  #
  # these should be shared between requests/renders so that the
  # caching can be effective

  class Renderer
    def initialize(cache = Spontaneous::Output.cache_templates?)
      @cache = cache
    end

    def render(output, params = {})
      output.model.with_visible do
        engine.render(output.content, context(output, params), output.name)
      end
    end

    def render_string(template_string, output, params = {})
      output.model.with_visible do
        engine.render_string(template_string, context(output, params), output.name)
      end
    end

    def context(output, params)
      context_class(output).new(output.content, params).tap do |context|
        context._renderer = renderer_for_context
      end
    end

    def renderer_for_context
      self
    end

    def context_class(output)
      if Spontaneous.development?
        generate_context_class(output)
      else
        context_cache[output.name] ||= generate_context_class(output)
      end
    end

    def context_cache
      @context_cache ||= {}
    end

    def generate_context_class(output)
      context_class = Class.new(Spontaneous::Output.context_class) do
        include Spontaneous::Output::Context::ContextCore
        include output.context
      end
      context_extensions.each do |mod|
        context_class.send :include, mod
      end
      context_class
    end

    def context_extensions
      []
    end

    def write_compiled_scripts=(state)
    end

    def template_exists?(root, template, format)
      engine.template_exists?(root, template, format)
    end

    def engine
      @engine ||= Spontaneous::Output::Template::PublishEngine.new(Spontaneous::Site.paths(:templates), @cache)
    end
  end

  class PublishRenderer < Renderer
    def initialize(cache = Spontaneous::Output.cache_templates?)
      super
      Thread.current[:_render_cache] = {}
    end

    def render_cache
      Thread.current[:_render_cache]
    end

    def write_compiled_scripts=(state)
      engine.write_compiled_scripts = state
    end

    def context_extensions
      [Spontaneous::Output::Context::PublishContext]
    end
  end

  class RequestRenderer < Renderer
    def engine
      @engine ||= Spontaneous::Output::Template::RequestEngine.new(Spontaneous::Site.paths(:templates), @cache)
    end
  end

  class PublishedRenderer < Renderer
    def initialize(revision, cache = Spontaneous::Output.cache_templates?)
      super(cache)
      @revision = revision
    end

    def render(output, params = {})
      request  = params[:request]
      response = params[:response]
      headers  = request.env
      # Test for static template
      path = template_path(output, false, request)
      return static_template(path) if ::File.exist?(path)
      # Attempt to render a published template
      super
    rescue Cutaneous::UnknownTemplateError => e
      template = publish_renderer.render(output, params)
      render_string(template, output, params)
    end

    def static_template(template_path)
      File.open(template_path)
    end

    def template_path(output, dynamic, request)
      Spontaneous::Output.output_path(@revision, output, dynamic, request.request_method)
    end

    def engine
      @engine ||= Spontaneous::Output::Template::RequestEngine.new(revision_root, @cache)
    end

    def publish_renderer
      @publish_renderer ||= PublishRenderer.new
    end

    def revision_root
      [Spontaneous::Site.revision_dir(@revision)/ "dynamic"]
    end
  end

  class PreviewRenderer < Renderer
    def render(output, params = {})
      rendered = super(output)
      request_renderer.render_string(rendered, output, params)
    end

    def render_string(template_string, output, params = {})
      rendered = super(template_string, output)
      request_renderer.render_string(rendered, output, params)
    end

    def renderer_for_context
      @renderer_for_context ||= PublishRenderer.new(@cache)
    end

    def request_renderer
      @request_renderer ||= RequestRenderer.new(@cache)
    end
  end
end
