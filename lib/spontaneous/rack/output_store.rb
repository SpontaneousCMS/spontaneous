module Spontaneous::Rack
  # This middleware tries to retrieve the given url from the
  # given asset store (at the given revision).
  class OutputStore
    include Spontaneous::Rack::Constants

    def self.assets(site)
      new(nil, site, :assets)
    end

    def initialize(app, site, namespace = :static)
      @app, @site, @namespace = app, site, namespace
    end

    def call(env)
      path = env[PATH_INFO]
      if (file = env[OUTPUT_STORE].load(@namespace, path, static: true))
        [200, headers(env, path), file]
      else
        pass(env)
      end
    end

    def headers(env, path)
      {HTTP_CONTENT_TYPE => mime_type(path)}
    end

    def mime_type(path)
      enforce_encoding ::Rack::Mime.mime_type(::File.extname(path), default_mime)
    end

    def enforce_encoding(mime_type)
      "#{mime_type};charset=#{charset}"
    end

    def default_mime
      'text/plain'
    end

    # TODO: Make this configurable on a site-by-site basis
    def charset
      'utf-8'
    end

    def pass(env)
      return not_found if @app.nil?
      @app.call(env)
    end

    def not_found
      [404, {}, ["Not found"]]
    end
  end
end
