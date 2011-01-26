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
      class Server < Spontaneous::Rack::Public

        use AroundFront

        before do
          content_type 'text/html', :charset => 'utf-8'
        end

      end
    end
  end
end


