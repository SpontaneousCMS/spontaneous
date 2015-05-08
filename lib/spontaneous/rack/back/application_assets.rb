require 'sprockets'

module Spontaneous::Rack::Back
  class ApplicationAssets < Base
    def initialize(app, charset = "UTF-8")
      css, js = %w(css js).map { |d| build_asset_handler(d, charset) }
      assets = ::Rack::File.new(Spontaneous.root / "public/@spontaneous/assets")
      @app = ::Rack::Builder.app do
        use Spontaneous::Rack::Static, :root => Spontaneous.application_dir, :urls => %W(/static)
        map("/assets") {
          use Spontaneous::Rack::CacheableFile
          run assets
        }
        map("/css")    { run css }
        map("/js")     { run js }
        run app
      end
    end

    def call(env)
      @app.call(env)
    end

    def build_asset_handler(dir, charset)
      environment = ::Sprockets::Environment.new(Spontaneous.application_dir ) do |env|
        env.append_path("#{dir}")
      end
      Spontaneous::Rack::AssetServer.new(environment, charset)
    end
  end
end
