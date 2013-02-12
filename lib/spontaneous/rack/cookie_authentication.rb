# encoding: UTF-8

module Spontaneous
  module Rack
    class CookieAuthentication
      def initialize(app)
        @app = app
      end

      def access_key(env)
        if login = Site.config.auto_login
          user = Spontaneous::Permissions::User.login(login)
          if user.access_keys.empty?
            user.generate_access_key(env["REMOTE_ADDR"])
          else
            user.access_keys.first
          end
        else
          request = ::Rack::Request.new(env)
          api_key = request.cookies[Spontaneous::Rack::AUTH_COOKIE]
          if api_key && key = Spontaneous::Permissions::AccessKey.authenticate(api_key, env["REMOTE_ADDR"])
            key
          else
            nil
          end
        end
      end

      def call(env)
        response = nil
        key = env[S::Rack::ACTIVE_KEY] = access_key(env)
        user = env[S::Rack::ACTIVE_USER] = key.user if key
        response = @app.call(env)
        response
      end
    end
  end
end
