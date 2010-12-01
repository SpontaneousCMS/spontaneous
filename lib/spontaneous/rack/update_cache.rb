# encoding: UTF-8

require 'less'

module Spontaneous
  module Rack
    class UpdateCache
      def initialize(app)
        @app = app
      end

      def call(env)
        response = nil
        Change.record do
          response = @app.call(env)
        end
        response
      end

    end

  end
end

