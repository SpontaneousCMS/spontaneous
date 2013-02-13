module Spontaneous::Rack::Back
  class Validation
    include Spontaneous::Rack::Constants

    def initialize(app)
      @app = app
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
      if (login = Spontaneous::Site.config.auto_login)
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

  class Authentication < Base
    use Validation

    def set_authentication_cookie(key)
      response.set_cookie(AUTH_COOKIE, {
        :value => key.key_id,
        :path => '/',
        :secure => request.ssl?,
        :httponly => true,
        :expires => Time.now
      })
    end

    def unset_authentication_cookie
      response.delete_cookie(AUTH_COOKIE, {
        :path => '/',
        :secure => request.ssl?,
        :httponly => true
      })
    end

    before do
      show_login_page unless user
    end

    post "/login" do
      login = params[:user][:login]
      password = params[:user][:password]
      origin = "#{NAMESPACE}#{params[:origin]}"
      if key = Spontaneous::Permissions::User.authenticate(login, password, env["REMOTE_ADDR"])
        set_authentication_cookie(key)
        if request.xhr?
          json({
            :key => key.key_id,
            :redirect => origin
          })
        else
          redirect origin, 302
        end
      else
        show_login_page( :login => login, :failed => true )
      end
    end

    post "/logout" do
      unset_authentication_cookie
      401
    end
  end
end
