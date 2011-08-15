# encoding: UTF-8

require "rack"
# require "sinatra"
require 'sinatra/base'

module Spontaneous
  module Rack
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
    autoload :Back, 'spontaneous/rack/back'
    autoload :Front, 'spontaneous/rack/front'
    autoload :Public, 'spontaneous/rack/public'
    autoload :Media, 'spontaneous/rack/media'
    autoload :Static, 'spontaneous/rack/static'
    autoload :AroundBack, 'spontaneous/rack/around_back'
    autoload :AroundFront, 'spontaneous/rack/around_front'
    autoload :AroundPreview, 'spontaneous/rack/around_preview'
    autoload :Reloader, 'spontaneous/rack/reloader'
  end
end

