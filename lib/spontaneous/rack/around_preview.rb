# encoding: UTF-8

module Spontaneous
  module Rack
    class AroundPreview
      def initialize(app)
        @app = app
        @renderer = Spontaneous::Output.preview_renderer
        Spontaneous::Output.renderer = @renderer
      end

      def call(env)
        env[Rack::RENDERER] = @renderer
        response = nil
        ::Content.scoped(nil, true) do
          response = @app.call(env)
        end
        response
      end
    end
  end
end
