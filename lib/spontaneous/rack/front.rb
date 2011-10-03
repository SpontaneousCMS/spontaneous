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
            run Spontaneous::Rack::Media.new
          end

          map "/" do
            use AroundFront
            use Reloader if Site.config.reload_classes
            run Server.new
          end
        end
      end
      class Server# < Spontaneous::Rack::Public
        include Spontaneous::Rack::Public

        def call(env)
          @response = ::Rack::Response.new
          @request = ::Rack::Request.new(env)
          render_path(@request.path_info)
        end
      end
    end
  end
end
