# encoding: UTF-8

module Spontaneous
  module Rack
    class AroundBack
      def initialize(app)
        @app = app
      end


      def call(env)
        response = nil
        Content.with_identity_map do
          response = @app.call(env)
        end
        response
      end
    end
  end
end
