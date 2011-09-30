# encoding: UTF-8

require 'less'

module Spontaneous
  module Rack
    class AroundBack
      def initialize(app)
        @app = CookieAuthentication.new(app)
      end


      def call(env)
        response = nil
        Content.with_identity_map do
          S::Render.with_preview_renderer do
            Change.record do
              response = @app.call(env)
            end
          end
        end
        response
      end
    end
  end
end
