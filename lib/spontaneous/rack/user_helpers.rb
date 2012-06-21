# encoding: UTF-8

module Spontaneous
  module Rack
    module UserHelpers

      def unauthorised!
        halt 403#, "You do not have the necessary permissions to update the '#{name}' field"
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

      def show_login_page(locals = {})
        halt(401, erb(:login, :views => Spontaneous.application_dir('/views'), :locals => locals))
      end
    end
  end
end
