# encoding: UTF-8

require 'less'

module Spontaneous
  module Rack
    class AroundBack
      def initialize(app)
        @app = app
      end

      def call(env)
        response = nil
        Content.with_identity_map do
          Change.record do
            response = @app.call(env)
          end
        end
        response
      end

    end

  end
end

