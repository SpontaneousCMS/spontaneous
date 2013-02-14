module Spontaneous::Rack::Middleware
  module Scope
    class Edit

      def initialize(app)
        @app = app
      end

      def call(env)
        response = nil
        Spontaneous::Content.scope(nil, false) do
          response = @app.call(env)
        end
        response
      end
    end

    class Preview
      include Spontaneous::Rack::Constants

      def initialize(app)
        @app = app
        @renderer = Spontaneous::Output.preview_renderer
        Spontaneous::Output.renderer = @renderer
      end

      def call(env)
        env[RENDERER] = @renderer
        response = nil
        Spontaneous::Content.scope(nil, true) do
          response = @app.call(env)
        end
        response
      end
    end

    POWERED_BY = {
      "X-Powered-By" => "Spontaneous CMS v#{Spontaneous::VERSION}"
    }

    class Front
      include Spontaneous::Rack::Constants

      def initialize(app)
        @app = app
        @renderer = Spontaneous::Output.published_renderer
      end

      def call(env)
        status = headers = body = nil
        env[RENDERER] = @renderer
        Spontaneous::Content.with_published do
          status, headers, body = @app.call(env)
        end
        [status, headers.merge(POWERED_BY), body]
      end
    end
  end
end
