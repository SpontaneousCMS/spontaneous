# encoding: UTF-8


module Spontaneous
  module Rack
    class AroundPreview < AroundBack
      def initialize(app)
        @app = app
      end

      def call(env)
        response = nil
        Content.with_identity_map do
          Spontaneous::Permissions.with_user(user(env)) do
            S::Render.with_preview_renderer do
              response = @app.call(env)
            end
          end
        end
        response
      end

    end
  end
end

