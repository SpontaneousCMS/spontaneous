require 'rack/fiber_pool'

module Spontaneous::Rack
  class FiberPool
    def initialize(app, options = {})
      @target_app = app
      @options    = options
    end

    def call(env)
      app.call(env)
    end

    def app
      @app ||= wrap_target_app
    end

    def wrap_target_app
      if Spontaneous.async?
        ::Rack::FiberPool.new(@target_app, @options)
      else
        @target_app
      end
    end
  end
end
