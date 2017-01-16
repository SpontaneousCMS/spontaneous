module Spontaneous::Rack
  # Sprockets (2.9.0) doesn't include charset information in the content-type
  # header. This wrapper class proxies all requests to a Sprockets enviroment
  # and adds in a charset setting to the content-type header of all responses
  class ApplicationAssetServer
    CONTENT_TYPE = "Content-Type".freeze

    def initialize(environment, charset = "UTF-8")
      @environment, @charset = environment, charset
    end

    def call(env)
      force_encoding(*@environment.call(env))
    end

    def force_encoding(status, headers, body)
      if (content_type = headers[CONTENT_TYPE])
        headers.update(CONTENT_TYPE => "#{content_type};charset=#{@charset}")
      end
      [status, headers, body]
    end
  end
end

