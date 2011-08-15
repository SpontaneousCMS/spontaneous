# encoding: UTF-8


module Spontaneous
  module Rack
    module HTTP
      METHOD_GET = "GET".freeze
      METHOD_POST = "POST".freeze
      METHOD_HEAD = "HEAD".freeze
      HTTP_CONTENT_LENGTH = "Content-Length".freeze
      HTTP_EXPIRES = "Expires".freeze
      HTTP_CACHE_CONTROL = "Cache-Control".freeze
      HTTP_LAST_MODIFIED = "Last-Modified".freeze
      HTTP_NO_CACHE = "max-age=0, must-revalidate, no-cache, no-store".freeze
    end
  end
end

