# encoding: UTF-8

require 'sass'
require 'sinatra/streaming'
require 'sprockets'

require 'spontaneous/rack/back/base'
require 'spontaneous/rack/back/alias'
require 'spontaneous/rack/back/assets'
require 'spontaneous/rack/back/authentication'
require 'spontaneous/rack/back/changes'
require 'spontaneous/rack/back/content'
require 'spontaneous/rack/back/csrf'
require 'spontaneous/rack/back/events'
require 'spontaneous/rack/back/field'
require 'spontaneous/rack/back/file'
require 'spontaneous/rack/back/index'
require 'spontaneous/rack/back/map'
require 'spontaneous/rack/back/page'
require 'spontaneous/rack/back/preview'
require 'spontaneous/rack/back/reloader'
require 'spontaneous/rack/back/schema'
require 'spontaneous/rack/back/scope'
require 'spontaneous/rack/back/site'
require 'spontaneous/rack/back/unsupported_browser'
require 'spontaneous/rack/back/user_admin'

module Spontaneous
  module Rack
    module Back
      include Spontaneous::Rack::Constants

      def self.editing_app
        ::Rack::Builder.app do
          use ::Rack::Lint
          use Scope::Back
          use Assets
          use UnsupportedBrowser
          use Authentication
          use CSRFHeader
          use Schema
          use Reloader
          use Index
          use CSRFVerification
          use Events
          map("/users") { run UserAdmin }
          use Site
          use Map
          use Field
          use Page
          use Content
          use Alias
          use Changes
          use File
          run lambda { |env| [ 404, {}, ["Not Found"] ] }
        end
      end


      def self.preview_app
        ::Rack::Builder.app do
          use ::Rack::Lint
          use Scope::Preview
          use Authentication
          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']
          use Spontaneous::Rack::CSS, :root => Spontaneous.instance.paths.expanded(:public)
          use Spontaneous::Rack::JS,  :root => Spontaneous.instance.paths.expanded(:public)
          use Reloader
          run Preview
        end
      end

      def self.application
        app = ::Rack::Builder.new do
          Spontaneous.instance.back_controllers.each do |namespace, controller_class|
            map namespace do
              run controller_class
            end
          end if Spontaneous.instance

          # Make all the files available under plugin_name/public/**
          # available under the URL /plugin_name/**
          Spontaneous.instance.plugins.each do |plugin|
            root = plugin.paths.expanded(:public)
            map "/#{plugin.file_namespace}" do
              use Spontaneous::Rack::CSS, :root => root
              run ::Rack::File.new(root)
            end
          end if Spontaneous.instance

          map "/media" do
            use ::Rack::Lint
            run Spontaneous::Rack::CacheableFile.new(Spontaneous.media_dir)
          end

          map NAMESPACE do
            run Spontaneous::Rack::Back.editing_app
          end

          map "/" do
            run Spontaneous::Rack::Back.preview_app
          end
        end
      end
    end
  end
end
