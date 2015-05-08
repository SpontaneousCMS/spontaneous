
module Spontaneous::Rack
  class CacheableFile < ::Rack::File
    include Constants

    YEARS   = 1
    SECONDS = (YEARS * 365.25*24*3600).ceil
    MAX_AGE = "max-age=#{SECONDS}, public".freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      if (status >= 200) && (status < 400)
        [status, caching_headers(headers), body]
      else
        [status, headers, body]
      end
    end

    # Send a far future Expires header and make sure that
    # the cache control is public
    def caching_headers(headers)
      headers.update({
        HTTP_CACHE_CONTROL => MAX_AGE,
        HTTP_EXPIRES => in_one_year.httpdate
      })
    end

    def in_one_year
      (Time.now + SECONDS)
    end
  end
end
