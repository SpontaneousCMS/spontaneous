# encoding: UTF-8

module Spontaneous
  module Rack
    class AroundBack
      def initialize(app)
        @app = app
      end


      def call(env)
        response = nil
        response = @app.call(env)
        response
      end
    end
  end
end
