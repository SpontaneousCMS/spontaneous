module Spontaneous::Rack
  # Sprockets (2.9.0) doesn't include charset information in the content-type
  # header. This wrapper class proxies all requests to a Sprockets enviroment
  # and adds in a charset setting to the content-type header of all responses
  class AssetServer
    def initialize(environment, charset = "UTF-8")
      @environment, @charset = environment, charset
    end

    def call(env)
      force_encoding(*@environment.call(env))
    end

    def force_encoding(status, headers, body)
      content_type = headers["Content-Type"]
      headers.update("Content-Type" => "#{content_type}; charset=#{@charset}")
      [status, headers, body]
    end
  end
end
