module Spontaneous::Rack::Middleware
  module Scope
    class Base
      def initialize(app, site, options = {})
        raise "Missing site instance" if site.nil?
        @app, @site, @options = app, site, options
      end

      def call(env)
        env[Spontaneous::Rack::SITE] = @site
        call!(env)
      end
    end

    class Edit < Base
      def call!(env)
        response = nil
        @site.model.scope(nil, false) do
          response = @app.call(env)
        end
        response
      end
    end

    class Preview < Base
      include Spontaneous::Rack::Constants

      def initialize(app, site, options = {})
        super
        @renderer = proc { |output| Spontaneous::Output.preview_renderer(output.format, @site) }
      end

      def call!(env)
        env[RENDERER] = @renderer
        response = nil
        @site.model.scope(nil, true) do
          response = @app.call(env)
        end
        response
      end
    end

    POWERED_BY = {
      "X-Powered-By" => "Spontaneous v#{Spontaneous::VERSION} <http://spontaneous.io>"
    }

    class Front < Base
      include Spontaneous::Rack::Constants

      def initialize(app, site, options = {})
        super
      end

      def call!(env)
        status = headers = body = nil
        env[REVISION] = revision = @site.published_revision
        env[RENDERER] = renderer(revision)
        env[OUTPUT_STORE] = @site.output_store.revision(revision)
        @site.model.with_published(@site) do
          status, headers, body = @app.call(env)
        end
        [status, headers.merge(POWERED_BY), body]
      end

      def renderer(revision)
        return uncached_renderer_for_revision(revision) if development?
        cached_renderer_for_revision(revision)
      end

      def cached_renderer_for_revision(revision)
        renderer_cache[revision]
      end

      def renderer_cache
        @renderer_cache ||= Hash.new { |h, revision|
          h[revision] = uncached_renderer_for_revision(revision)
        }
      end

      def uncached_renderer_for_revision(revision)
        proc { |output| Spontaneous::Output.published_renderer(output.format, @site, revision) }
      end

      def development?
        Spontaneous.development?
      end
    end
  end
end
