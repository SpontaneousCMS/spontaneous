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


          Spontaneous.instance.front_controllers.each do |namespace, controller_class|
            map namespace do
              run controller_class
            end
          end if Spontaneous.instance

          # Make all the files available under plugin_name/public/**
          # available under the URL /plugin_name/**
          Spontaneous.instance.plugins.each do |plugin|
            map "/#{plugin.name}" do
              run ::Rack::File.new(plugin.paths.expanded(:public))
            end
          end if Spontaneous.instance

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
      class Server < Sinatra::Base
        include Spontaneous::Rack::Public

        def call!(env)
          @env = env
          @response = ::Sinatra::Response.new
          @request = ::Sinatra::Request.new(env)
          render_path(@request.path_info)
        end
      end
    end
  end
end
