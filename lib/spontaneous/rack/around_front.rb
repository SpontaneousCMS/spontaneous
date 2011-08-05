# encoding: UTF-8

module Spontaneous
  module Rack
    POWERED_BY = {
      "X-Powered-By" => "Spontaneous CMS v#{Spontaneous::VERSION}"
    }

    class AroundFront
      def initialize(app)
        @app = app
      end

      def call(env)
        status = headers = body = nil
        Content.with_identity_map do
          S::Render.with_published_renderer do
            Site.with_published do
              status, headers, body = @app.call(env)
            end
          end
        end
        [status, headers.merge(POWERED_BY), body]
      end
    end

  end
end

