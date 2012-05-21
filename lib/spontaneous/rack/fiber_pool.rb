require 'rack/fiber_pool'

module Spontaneous::Rack
  class FiberPool
    def initialize(app, options = {})
      @app     = app
      @options = options
    end

    def call(env)
      app.call(env)
    end

    def app
      if Spontaneous.async?
        ::Rack::FiberPool.new(@app, @options)
      else
        @app
      end
    end
  end
end
