# encoding: UTF-8

require 'sinatra/base'

module Spontaneous
  module Rack
    module Front
      include Spontaneous::Rack::Middleware

      def self.make_controller(controller_class, site)
        controller_class
      end

      def self.front_app(site)
        ::Rack::Builder.app do
          use Reloader, site if Spontaneous.development?
          run Server.new
        end
      end

      def self.application(site = ::Spontaneous.instance)
        ::Rack::Builder.new do
          use Scope::Front, site
          use Spontaneous::Rack::Static, root: Spontaneous.revision_dir / 'public', urls: %w[/], try: ['.html', 'index.html', '/index.html']

          Spontaneous.instance.front.middleware.each do |args, block|
            use(*args, &block)
          end

          Spontaneous.instance.front_controllers.each do |namespace, controller_class|
            map namespace do
              run controller_class
            end
          end

          # Make all the files available under plugin_name/public/**
          # available under the URL /plugin_name/**
          # Only used in preview mode
          site.plugins.each do |plugin|
            map "/#{plugin.name}" do
              run ::Rack::File.new(plugin.paths.expanded(:public))
            end
          end

          map '/assets' do
            use Spontaneous::Rack::CacheableFile
            run Spontaneous::Rack::OutputStore.assets(site)
          end

          map '/media' do
            use Spontaneous::Rack::CacheableFile
            run ::Rack::File.new(Spontaneous.media_dir)
          end

          use Spontaneous::Rack::OutputStore, site

          run Spontaneous::Rack::Front.front_app(site)
        end
      end

      class Server < Sinatra::Base
        include Spontaneous::Rack::Public

        def call!(env)
          @env = env
          @response = ::Sinatra::Response.new
          @request  = ::Sinatra::Request.new(env)
          @params   = indifferent_params(@request.params)

          render_path(@request.path_info)
        end

        def site
          @site ||= env[Spontaneous::Rack::SITE]
        end
      end
    end
  end
end
