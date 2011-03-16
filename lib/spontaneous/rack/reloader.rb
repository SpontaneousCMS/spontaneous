# encoding: UTF-8


module Spontaneous
  module Rack
    class Reloader
      def initialize(app)
        @app = app
      end


      def call(env)
        puts "Reloading..."
        response = @app.call(env)
      end
    end # Reloader
  end # Rack
end # Spontaneous


