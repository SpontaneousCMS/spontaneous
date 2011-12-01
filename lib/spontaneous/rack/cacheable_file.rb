
module Spontaneous::Rack
  class CacheableFile < ::Rack::File
    include HTTP

    TEN_YEARS = 10*365*24*3600
    MAX_AGE =  "max-age=#{TEN_YEARS}, public".freeze

    def initialize(file_root)
      super(file_root, 'public')
    end

    def call(env)
      status, headers, body = super
      [status, caching_headers(headers), body]
    end

    # Send a far future Expires header and make sure that
    # the cache control is public
    def caching_headers(headers)
      headers.merge({
        HTTP_CACHE_CONTROL => MAX_AGE,
        HTTP_EXPIRES => (Time.now + TEN_YEARS).httpdate
      })
    end
  end
end
