
module Spontaneous::Rack::Back
  class SiteAssets < Base
    def initialize(site)
      @roots = site.paths(:compiled_assets)
    end

    def call(env)
      app.call(env)
    end

    def app
      @app ||= build_app(@roots)
    end

    def build_app(roots)
      Rack::Builder.new do
        roots.each do |root|
          use ::Rack::Static, urls: ['/'], root: root
        end
        run lambda { |env| [404, {'Content-Type' => 'text/plain'}, ['Not found']] }
      end
    end
  end
end
