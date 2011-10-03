# encoding: UTF-8

module Spontaneous
  module Rack
    class CookieAuthentication
      def initialize(app)
        @app = app
      end

      def current_user(env)
        if login = Site.config.auto_login
          user = Spontaneous::Permissions::User[:login => login]
        else
          request = ::Rack::Request.new(env)
          api_key = request.cookies[Spontaneous::Rack::AUTH_COOKIE]
          if api_key && key = Spontaneous::Permissions::AccessKey.authenticate(api_key)
            key.user
          else
            nil
          end
        end
      end

      def call(env)
        response = nil
        user = env[S::Rack::ACTIVE_USER] = current_user(env)
        response = @app.call(env)
        response
      end
    end
  end
end
