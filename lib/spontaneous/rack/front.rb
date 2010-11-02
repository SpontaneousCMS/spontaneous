# encoding: UTF-8

require 'sinatra/base'

module Spontaneous
  module Rack
    module Front
      def self.application
        app = ::Rack::Builder.new {
          use ::Rack::CommonLogger, STDERR  #unless server.name =~ /CGI/
          # use ::Rack::ShowExceptions

          map "/" do
            run Server
          end
        }
      end
      class Server < Sinatra::Base

        before do
          content_type 'text/html', :charset => 'utf-8'
        end


        # preview routes
        get "/" do
          Site.root.render
        end

        get "*" do
          Site[params[:splat].first].render
        end
      end
    end
  end
end


