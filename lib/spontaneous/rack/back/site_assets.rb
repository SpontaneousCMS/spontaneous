
module Spontaneous::Rack::Back
  class SiteAssets < Base
    def initialize(charset = "UTF-8")
      @environment = Spontaneous::Asset::Environment.preview
      @app = Spontaneous::Rack::AssetServer.new(@environment, charset)
    end

    def call(env)
      @app.call(env)
    end
  end
end
