# encoding: UTF-8


module Spontaneous
  module Rack
    class Reloader
      def initialize(app)
        @app = app
        @cooldown = 3
        @last = (Time.now - @cooldown)
      end


      def call(env)
        if @cooldown and Time.now > @last + @cooldown
          if Thread.list.size > 1
            Thread.exclusive{ reload! }
          else
            reload!
          end

          @last = Time.now
        end

        @app.call(env)
      end

      def reload!
        Spontaneous.reload!
      end
    end # Reloader
  end # Rack
end # Spontaneous

