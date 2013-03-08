# encoding: UTF-8

module Spontaneous
  module Rack
    module Back

      autoload :Base,               'spontaneous/rack/back/base'
      autoload :Alias,              'spontaneous/rack/back/alias'
      autoload :ApplicationAssets,  'spontaneous/rack/back/application_assets'
      autoload :Changes,            'spontaneous/rack/back/changes'
      autoload :Content,            'spontaneous/rack/back/content'
      autoload :Events,             'spontaneous/rack/back/events'
      autoload :Field,              'spontaneous/rack/back/field'
      autoload :File,               'spontaneous/rack/back/file'
      autoload :Helpers,            'spontaneous/rack/back/helpers'
      autoload :Index,              'spontaneous/rack/back/index'
      autoload :Login,              'spontaneous/rack/back/login'
      autoload :Map,                'spontaneous/rack/back/map'
      autoload :Page,               'spontaneous/rack/back/page'
      autoload :Preview,            'spontaneous/rack/back/preview'
      autoload :Schema,             'spontaneous/rack/back/schema'
      autoload :Site,               'spontaneous/rack/back/site'
      autoload :SiteAssets,         'spontaneous/rack/back/site_assets'
      autoload :UnsupportedBrowser, 'spontaneous/rack/back/unsupported_browser'
      autoload :UserAdmin,          'spontaneous/rack/back/user_admin'

      include Spontaneous::Rack::Constants
      include Spontaneous::Rack::Middleware

      def self.make_controller(controller_class)
        controller_class.helpers Helpers
        ::Rack::Builder.app do
          use Scope::Edit
          use Authenticate::Init
          use Authenticate::Edit
          use CSRF::Header
          use CSRF::Verification
          run controller_class
        end
      end

      def self.editing_app
        ::Rack::Builder.app do
          use ::Rack::Lint if Spontaneous.development?
          use Scope::Edit
          use ApplicationAssets
          use UnsupportedBrowser
          use Authenticate::Init
          use Login
          # Everything after this handler requires authentication
          use Authenticate::Edit
          use CSRF::Header
          # Schema has to come before Reloader because we need to be able to
          # present the conflict resolution interface without running through
          # the schema validation step
          map("/schema")  { run Schema }
          use Reloader
          use Index
          # Everything after this middleware requires a valid CSRF token
          use CSRF::Verification
          map("/events")  { run Events }
          map("/users")   { run UserAdmin }
          map("/site")    { run Site }
          map("/map")     { run Map }
          map("/field")   { run Field }
          map("/page")    { run Page }
          map("/content") { run Content }
          map("/alias")   { run Alias }
          map("/changes") { run Changes }
          map("/file")    { run File::Simple }
          map("/shard")   { run File::Sharded }
          run lambda { |env| [ 404, {}, ["Not Found"] ] }
        end
      end


      def self.preview_app
        ::Rack::Builder.app do
          use ::Rack::Lint if Spontaneous.development?
          use Scope::Preview
          use Authenticate::Init
          # Preview authentication redirects to /@spontaneous rather than
          # showing a login screen. This way if you go to rhe root of the site
          # as an unauthorised user (say for the first time) you will get sent
          # to the editing interface wrapper rather than being presented with
          # the preview site.
          use Authenticate::Preview
          use CSRF::Header
          map("/assets") { run SiteAssets.new }
          use Spontaneous::Rack::Static, :root => Spontaneous.root / "public",
            :urls => %w[/],
            :try => ['.html', 'index.html', '/index.html']
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
