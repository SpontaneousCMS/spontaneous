module Spontaneous::Rack::Middleware
  class Transaction
    def initialize(app, site)
      @app = app
      @site = site
    end

    def call(env)
      @site.transaction do |conn|
        @app.call(env)
      end
    end
  end
end
