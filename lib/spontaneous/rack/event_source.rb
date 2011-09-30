# encoding: UTF-8

module Spontaneous
  module Rack
    class EventSource < ::Simultaneous::Rack::EventSource
      # def initialize
      #   @messenger = ::Simultaneous::Rack::EventSource.new
      #   @app = @messenger.app
      # end

      # def call(env)
      #   user = env[S::Rack::ACTIVE_USER]
      #   if user.nil?
      #     unauthorized!
      #   else
      #     request = ::Rack::Request.new(env)
      #     key = request[S::Rack::KEY_PARAM]
      #     if ::S::Permissions::AccessKey.valid?(key, user)
      #       @app.call(env)
      #     else
      #       unauthorized!
      #     end
      #   end
      # end

      # def unauthorized!
      #   [401, {}, "Unauthorized"]
      # end
    end
  end
end
