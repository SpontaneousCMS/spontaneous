
module Spontaneous::Rack::Back
  class SiteAssets < Base
    def initialize(site)
      @roots = site.paths(:compiled_assets)
    end

    def call(env)
      if (resp = find(env))
        return resp
      end
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

    def find(env)
      apps.map { |app| app.call(env) }.detect { |code, headers, body| code < 400 }
    end

    def apps
      @apps ||= build_apps(@roots)
    end

    def build_apps(roots)
      roots.map { |root| ::Rack::Static.new(nil, urls: ['/'], root: root) }
    end
  end
end
