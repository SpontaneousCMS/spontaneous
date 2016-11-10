
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

  class PreviewTransaction
    attr_reader :site

    def initialize(site)
      @site = site
    end

    def publishing?
      false
    end

    def asset_manifests
      site.asset_manifests
    end
  end

  class Renderer
    def initialize(site, cache = Spontaneous::Output.cache_templates?)
      @site  = site
      @cache = cache
    end

    def render(output, params = {}, parent_context = nil)
      output.model.with_visible do
        _render(output.renderable_content, context(output, params, parent_context), output.name)
      end
    end

    def render_string(template_string, output, params = {}, parent_context = nil)
      output.model.with_visible do
        _render_string(template_string, context(output, params, parent_context), output.name)
      end
    end

    def _render(content, context, format)
      engine.render(content, context, format)
    end

    def _render_string(template_string, context, format)
      engine.render_string(template_string, context, format)
    end

    protected :_render, :_render_string

    def context(output, params, parent)
      renderable = Spontaneous::Output::Renderable.new(output.renderable_content)
      context_class(output).new(renderable, params, parent).tap do |context|
        context.site = @site
        context.__output = output
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
      site = @site
      context_class = Class.new(Spontaneous::Output.context_class) do
        include Spontaneous::Output::Context::ContextCore
        include output.context(site)
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

    def template_exists?(template, format)
      engine.template_exists?(template, format)
    end

    def template_location(template, format)
      engine.template_location(template, format)
    end

    def is_dynamic_template?(template_string)
      second_pass_engine.dynamic_template?(template_string)
    end

    def is_model?(klass)
      klass < @site.model
    end

    def engine
      @engine ||= create_engine(:PublishEngine)
    end

    def second_pass_engine
      @second_pass_engine ||= create_engine(:RequestEngine)
    end

    def create_engine(engine_class, template_roots = @site.paths(:templates))
      Spontaneous::Output::Template.const_get(engine_class).new(template_roots, @cache)
    end
  end

  class PublishRenderer < Renderer
    attr_reader :transaction

    def initialize(transaction, cache = Spontaneous::Output.cache_templates?)
      super(transaction.site, cache)
      @transaction = transaction
      Thread.current[:_render_cache] = {}
    end

    def render_cache
      Thread.current[:_render_cache]
    end

    # Disabled for moment
    def write_compiled_scripts=(state)
      engine.write_compiled_scripts = false # state
    end

    def context_extensions
      [Spontaneous::Output::Context::PublishContext]
    end
  end

  class RequestRenderer < Renderer
    def engine
      @engine ||= create_engine(:RequestEngine)
    end
  end

  class PublishedRenderer < Renderer
    attr_reader :revision

    def initialize(site, revision, cache = Spontaneous::Output.cache_templates?)
      super(site, cache)
      @revision = revision
      @output_store = @site.output_store.revision(@revision)
    end

    def render(output, params = {}, parent_context = nil)
      render!(output, params, parent_context)
    rescue Cutaneous::UnknownTemplateError => _e
      render_on_demand(output, params, parent_context)
    end

    def render!(output, params, parent_context)
      # See `spontaneous/output/store/transaction.rb` for the `store_output`
      # clauses that explain this reasoning...
      if output.protected?
        # We can be sure that if the output says it's protected then it'll be
        # here
        if (template = @output_store.protected_template(output))
          return template
        end
      elsif output.dynamic?
        # If this is true then the template is definitely stored as dynamic. If
        # it's false it's still possible for the template to be held under the
        # dynamic namespace because the rendered template may contain dynamic
        # tags.
        if (template = @output_store.dynamic_template(output))
          return render_dynamic_template(template, output, params, parent_context)
        end
      end
      # The cases we have left to handle are:
      # a. Completely static templates
      # b. Dynamic templates generated by a static output (e.g. HTML)
      #
      # If we're running behind a reverse proxy then it's most likely that it
      # will be handling the static templates and we will never be asked to
      # render them here.
      #
      # But, if we're running without a reverse proxy (e.g. as it would be on
      # Heroku) then this method has to handle every request and in that case
      # it's more likely that nearly all the requests will be for static
      # pages...
      #
      # I've written the below assuming that the most usual case is to be
      # running behind a reverse proxy.
      #
      # TODO: There is no truly best way to order these attempts to find an
      # existing template unless I surface a configuration option to make the
      # order of these two requests explicit & configurable per-site.
      if (template = @output_store.dynamic_template(output))
        return render_dynamic_template(template, output, params, parent_context)
      end
      if (template = @output_store.static_template(output))
        return template
      end
      if (template = @output_store.protected_template(output))
        return template
      end
      logger.warn("missing template for #{output.page.path}#{output.extension(false)}")
      render_on_demand(output, params, parent_context)
    end

    def render_dynamic_template(template, output, params, parent_context)
      engine.render_template(template, context(output, params, parent_context), output.name)
    end

    def render_on_demand(output, params, parent_context)
      template = publish_renderer.render(output, params)
      render_string(template, output, params)
    end

    def engine
      @engine ||= create_engine(:RequestEngine, revision_root)
    end

    def publish_renderer
      @publish_renderer ||= PublishRenderer.new(publish_transaction)
    end

    def publish_transaction
      Spontaneous::Publishing::Transaction.new(@site, revision, nil)
    end

    def revision_root
      [@site.revision_dir(@revision)/ "dynamic"]
    end
  end

  class PreviewRenderer < Renderer
    def render(output, params = {}, parent_context = nil)
      rendered = super(output)
      request_renderer.render_string(rendered, output, params, parent_context)
    end

    def render_string(template_string, output, params = {}, parent_context = nil)
      rendered = super(template_string, output)
      request_renderer.render_string(rendered, output, params, parent_context)
    end

    def publish_transaction
      PreviewTransaction.new(@site)
    end

    def renderer_for_context
      @renderer_for_context ||= PublishRenderer.new(publish_transaction, @cache)
    end

    def request_renderer
      @request_renderer ||= RequestRenderer.new(@site, @cache)
    end
  end
end
