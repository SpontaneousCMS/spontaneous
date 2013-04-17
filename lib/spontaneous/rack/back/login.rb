module Spontaneous::Rack::Back
  class Login < Base
    include TemplateHelpers

    def set_authentication_cookie(key)
      response.set_cookie(AUTH_COOKIE, {
        :value => key.key_id,
        :path => '/',
        :secure => request.ssl?,
        :httponly => true,
        :expires => (Time.now + SESSION_LIFETIME)
      })
    end

    def unset_authentication_cookie
      response.delete_cookie(AUTH_COOKIE, {
        :path => '/',
        :secure => request.ssl?,
        :httponly => true
      })
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

    delete "/logout" do
      unset_authentication_cookie
      401
    end
  end
end
