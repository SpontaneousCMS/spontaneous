# encoding: UTF-8

require "rack"
require "sinatra/base"

module Spontaneous
  module Rack
    module Constants
      METHOD_GET = "GET".freeze
      METHOD_POST = "POST".freeze
      METHOD_HEAD = "HEAD".freeze
      HTTP_CONTENT_LENGTH = "Content-Length".freeze
      HTTP_EXPIRES = "Expires".freeze
      HTTP_CACHE_CONTROL = "Cache-Control".freeze
      HTTP_LAST_MODIFIED = "Last-Modified".freeze
      HTTP_NO_CACHE = "max-age=0, must-revalidate, no-cache, no-store".freeze

      NAMESPACE      = "/@spontaneous".freeze
      AUTH_COOKIE    = "spontaneous_api_key".freeze
      SESSION_LIFETIME = 1.year
      # Rack env params
      ACTIVE_USER    = "spot.user".freeze
      ACTIVE_KEY     = "spot.key".freeze
      RENDERER       = "spot.renderer".freeze
      CSRF_VALID     = "spot.csrf_valid".freeze
      CSRF_TOKEN     = "spot.csrf_token".freeze

      CSRF_HEADER    = "X-CSRF-Token".freeze
      CSRF_PARAM     = "__token".freeze
      CSRF_ENV       = ("HTTP_" << CSRF_HEADER.upcase.gsub(/-/, "_")).freeze

      EXPIRES_MAX = DateTime.parse("Thu, 31 Dec 2037 23:55:55 GMT").httpdate
    end

    include Constants

    class << self
      def application
        case Spontaneous.mode
        when :back
          Back.application
        when :front
          Front.application
        end
      end

      def port
        Site.config.port
      end

      def make_front_controller(controller_class)
        Spontaneous::Rack::Front.make_controller(controller_class)
      end

      def make_back_controller(controller_class)
        Spontaneous::Rack::Back.make_controller(controller_class)
      end
    end

    class ServerBase < ::Sinatra::Base
      include Constants

      set :environment, Proc.new { Spontaneous.environment }
    end

    autoload :Assets,               'spontaneous/rack/assets'
    autoload :Back,                 'spontaneous/rack/back'
    autoload :CSS,                  'spontaneous/rack/css'
    autoload :CacheableFile,        'spontaneous/rack/cacheable_file'
    autoload :EventSource,          'spontaneous/rack/event_source'
    autoload :Front,                'spontaneous/rack/front'
    autoload :JS,                   'spontaneous/rack/js'
    autoload :Middleware,           'spontaneous/rack/middleware'
    autoload :PageController,       "spontaneous/rack/page_controller"
    autoload :Public,               'spontaneous/rack/public'
    autoload :SSE,                  'spontaneous/rack/sse'
    autoload :Static,               'spontaneous/rack/static'
  end
end
