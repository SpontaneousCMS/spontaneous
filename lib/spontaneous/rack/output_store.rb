module Spontaneous::Rack
  # This middleware tries to retrieve the given url from the given asset store
  # (at the given revision).  It's pretty naive at the moment and doesn't
  # support all the HTTP features it should.
  class OutputStore
    include Spontaneous::Rack::Constants

    ALLOWED_VERBS = ::Rack::File::ALLOWED_VERBS

    def self.assets(site)
      new(nil, site, :assets)
    end

    def initialize(app, site, namespace = :static)
      @app, @site, @namespace = app, site, namespace
    end

    def call(env)
      return pass(env) unless ALLOWED_VERBS.include?(env[REQUEST_METHOD])
      path, body = load_from_output_store(env)
      return pass(env) if body.nil?
      headers = headers(env, path, body)
      body = [] if env[REQUEST_METHOD] == "HEAD".freeze
      [200, headers, body]
    end

    def load_from_output_store(env)
      path = path_with_extension(env[PATH_INFO])
      [path, env[OUTPUT_STORE].load(@namespace, path, static: true)]
    end

    # Templates are stored in the backend with an extension,
    # but the page urls are given without a .html extension
    # so we need to add this.
    def path_with_extension(path)
      return 'index.html'.freeze if path == Spontaneous::SLASH
      return path unless ::File.extname(path).blank?
      "#{path}.html"
    end

    def headers(env, path, body)
      {HTTP_CONTENT_TYPE => mime_type(path), HTTP_CONTENT_LENGTH => body.length.to_s}
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
