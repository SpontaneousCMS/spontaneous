require 'spontaneous/rack/back/base'
require 'spontaneous/rack/back/helpers'

module Spontaneous::Rack::Middleware
  module Authenticate
    class Init
      include Spontaneous::Rack::Constants

      def initialize(app, site)
        @app, @site = app, site
      end

      def call(env)
        if (key = authenticate(env))
          env[ACTIVE_KEY]  = key
          env[ACTIVE_USER] = key.user
        end
        @app.call(env)
      end

      def authenticate(env)
        remote_addr = env["REMOTE_ADDR"]
        if (login = @site.config.auto_login)
          auto_login(login, remote_addr)
        else
          cookie_login(env, remote_addr)
        end
      end

      def auto_login(login, remote_addr)
        user = Spontaneous::Permissions::User.login(login)
        if user.access_keys.empty?
          user.generate_access_key(remote_addr)
        else
          user.access_keys.first
        end
      end

      def cookie_login(env, remote_addr)
        request = ::Rack::Request.new(env)
        key_id  = request.cookies[AUTH_COOKIE]
        return nil unless key_id
        key = Spontaneous::Permissions::AccessKey.authenticate(key_id, remote_addr)
        return nil unless key
        key
      end
    end


    class Edit < Spontaneous::Rack::Back::Base
      include Spontaneous::Rack::Back::TemplateHelpers

      before do
        show_login_page unless user
      end
    end

    class Preview < Spontaneous::Rack::Back::Base
      before do
        redirect NAMESPACE, 302 unless user
      end
    end
  end
end

