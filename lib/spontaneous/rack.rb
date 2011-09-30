# encoding: UTF-8

require "rack"
# require "sinatra"
require 'sinatra/base'

module Spontaneous
  module Rack
    NAMESPACE = "/@spontaneous".freeze
    ACTIVE_USER = "SPONTANEOUS_USER".freeze
    AUTH_COOKIE = "spontaneous_api_key".freeze
    KEY_PARAM = "__key".freeze

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
    end

    class ServerBase < ::Sinatra::Base
      set :environment, Proc.new { Spontaneous.environment }

      # serve static files from the app's public dir

      ## removed these as sinatra now sets utf-8 by default
      # mime_type :js,  'text/javascript; charset=utf-8'
      # mime_type :css, 'text/css; charset=utf-8'

      # before do
      #   ## globally setting this screws up auto content type setting by send_file
      #   # content_type 'text/html', :charset => 'utf-8'
      #   if Spontaneous.development?
      #     # Templates.clear_cache!
      #   end
      # end
    end

    autoload :HTTP, 'spontaneous/rack/http'
    autoload :Assets, 'spontaneous/rack/assets'
    autoload :Back, 'spontaneous/rack/back'
    autoload :Front, 'spontaneous/rack/front'
    autoload :Public, 'spontaneous/rack/public'
    autoload :Authentication, 'spontaneous/rack/authentication'
    autoload :Media, 'spontaneous/rack/media'
    autoload :Static, 'spontaneous/rack/static'
    autoload :CookieAuthentication, 'spontaneous/rack/cookie_authentication'
    autoload :QueryAuthentication, 'spontaneous/rack/query_authentication'
    autoload :AroundBack, 'spontaneous/rack/around_back'
    autoload :AroundFront, 'spontaneous/rack/around_front'
    autoload :AroundPreview, 'spontaneous/rack/around_preview'
    autoload :Reloader, 'spontaneous/rack/reloader'
    autoload :EventSource, 'spontaneous/rack/event_source'
  end
end
