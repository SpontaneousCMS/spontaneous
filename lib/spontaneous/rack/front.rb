# encoding: UTF-8

require 'sinatra/base'

module Spontaneous
  module Rack
    module Front
      def self.application
        app = ::Rack::Builder.new do
          # use ::Rack::CommonLogger, STDERR  #unless server.name =~ /CGI/
          # use ::Rack::ShowExceptions

          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']

          map "/media" do
            run Spontaneous::Rack::Media
          end

          map "/" do
            run Server
          end
        end
      end
      class Server < Spontaneous::Rack::Public

        use AroundFront

        before do
          content_type 'text/html', :charset => (Site.config.default_charset || 'utf-8')
        end
      end
    end
  end
end


