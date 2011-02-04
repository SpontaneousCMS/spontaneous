# encoding: UTF-8

module Spontaneous
  module Rack
    class AroundFront
      def initialize(app)
        @app = app
      end

      def call(env)
        response = nil
        Content.with_identity_map do
          S::Render.with_published_engine do
            Site.with_published do
              response = @app.call(env)
            end
          end
        end
        response
      end
    end

  end
end

