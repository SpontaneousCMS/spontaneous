# encoding: UTF-8

require 'less'

module Spontaneous
  module Rack
    class AroundBack
      def initialize(app)
        @app = app
      end

      def user(env)
        if login = Spontaneous.config.auto_login
          user = Spontaneous::Permissions::User[:login => login]
        else
          request = ::Rack::Request.new(env)
          api_key = request.cookies[Spontaneous::Rack::Back::AUTH_COOKIE]
          if api_key && key = Spontaneous::Permissions::AccessKey.authenticate(api_key)
            key.user
          else
            nil
          end
        end
      end

      def call(env)
        response = nil
        Content.with_identity_map do
          Spontaneous::Permissions.with_user(user(env)) do
            S::Render.with_preview_renderer do
              Change.record do
                response = @app.call(env)
              end
            end
          end
        end
        response
      end

    end

  end
end

