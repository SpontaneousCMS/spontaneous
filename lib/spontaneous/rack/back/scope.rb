module Spontaneous::Rack::Back
  module Scope
    class Back

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
  end
end
