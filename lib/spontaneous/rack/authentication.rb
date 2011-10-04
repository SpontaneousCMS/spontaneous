# encoding: UTF-8

require 'rack'

module Spontaneous
  module Rack
    module Authentication

      module Helpers
        def authorised?
          if cookie = request.cookies[AUTH_COOKIE]
            true
          else
            false
          end
        end

        def unauthorised!
          halt 401#, "You do not have the necessary permissions to update the '#{name}' field"
        end

        def api_key
          request.cookies[AUTH_COOKIE]
        end

        def user
          @user ||= load_user
        end

        def load_user
          env[ACTIVE_USER]
        end
      end

      def self.registered(app)
        app.helpers Authentication::Helpers

        app.post "/reauthenticate" do
          if key = Spot::Permissions::AccessKey.authenticate(params[:api_key])
            response.set_cookie(AUTH_COOKIE, {
              :value => key.key_id,
              :path => '/'
            })
            origin = "#{NAMESPACE}#{params[:origin]}"
            redirect origin, 302
          else
            halt(401, erb(:login, :locals => { :invalid_key => true }))
          end
        end

        app.post "/login" do
          login = params[:user][:login]
          password = params[:user][:password]
          origin = "#{NAMESPACE}#{params[:origin]}"
          if key = Spontaneous::Permissions::User.authenticate(login, password)
            response.set_cookie(AUTH_COOKIE, {
              :value => key.key_id,
              :path => '/'
            })
            if request.xhr?
              json({
                :key => key.key_id,
                :redirect => origin
              })
            else
              redirect origin, 302
            end
          else
            halt(401, erb(:login, :locals => { :login => login, :failed => true }))
          end
        end
      end


      def requires_authentication!(options = {})
        first_level_exceptions = (options[:except_all] || []).concat(["#{NAMESPACE}/login", "#{NAMESPACE}/reauthenticate"] )
        second_level_exceptions = (options[:except_key] || [])
        before do
          unless first_level_exceptions.any? { |e| e === request.path }
            ignore_key = second_level_exceptions.any? { |e| e === request.path }
            valid_key = ignore_key || Spontaneous::Permissions::AccessKey.valid?(params[KEY_PARAM], user)
            unless (user and valid_key)
              halt(401, erb(:login, :locals => { :login => '' }))
            end
          end
        end
      end
    end
  end
end
