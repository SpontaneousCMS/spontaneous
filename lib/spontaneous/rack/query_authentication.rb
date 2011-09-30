# encoding: UTF-8

module Spontaneous
  module Rack
    # Rack middleware that only allows access if the access key passed in the request query
    # matches that used in the cookie
    #
    # Depends on CookieAuthentication being in the chain *before* this app to set up the current user in the env
    class QueryAuthentication
      def initialize(app)
        @app = app
      end

      def call(env)
        user = env[S::Rack::ACTIVE_USER]
        if user.nil?
          unauthorized!
        else
          request = ::Rack::Request.new(env)
          key = request[S::Rack::KEY_PARAM]
          if ::S::Permissions::AccessKey.valid?(key, user)
            @app.call(env)
          else
            unauthorized!
          end
        end
      end

      def unauthorized!
        [401, {}, "Unauthorized"]
      end
    end
  end
end

