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
      autoload :Private,            'spontaneous/rack/back/private'
      autoload :Schema,             'spontaneous/rack/back/schema'
      autoload :Site,               'spontaneous/rack/back/site'
      autoload :SiteAssets,         'spontaneous/rack/back/site_assets'
      autoload :UnsupportedBrowser, 'spontaneous/rack/back/unsupported_browser'
      autoload :UserAdmin,          'spontaneous/rack/back/user_admin'

      include Spontaneous::Rack::Constants
      include Spontaneous::Rack::Middleware

      def self.make_controller(app, site)
        app.helpers Helpers if app.respond_to?(:helpers)
        app
      end

      def self.api_handlers
        [['/events', Events],
         ['/users', UserAdmin],
         ['/site', Site],
         ['/map', Map],
         ['/field', Field],
         ['/page', Page],
         ['/content', Content],
         ['/alias', Alias],
         ['/changes', Changes],
         ['/file', File::Simple],
         ['/shard', File::Sharded]]
      end

      def self.editing_app(site)
        ::Rack::Builder.app do
          use ::Rack::ShowExceptions if site.development?
          use Scope::Edit, site
          use Transaction, site
          use ApplicationAssets
          use UnsupportedBrowser
          use Authenticate::Init, site
          use Login
          use Authenticate::Edit # Everything after this handler requires authentication
          use CSRF::Header
          # Schema has to come before Reloader because we need to be able to
          # present the conflict resolution interface without running through
          # the schema validation step
          map('/schema')  { run Schema }
          use Reloader, site
          use Index
          map('/private') {
            use Scope::Preview, site
            run Private
          }
          use CSRF::Verification # Everything after this middleware requires a valid CSRF token
          Back.api_handlers.each do |path, app|
            map(path) { run app }
          end
          run lambda { |env| [ 404, {}, ['Not Found'] ] }
        end
      end


      def self.preview_app(site)
        ::Rack::Builder.app do
          use ::Rack::ShowExceptions if site.development?
          use ::Rack::Lint if Spontaneous.development?
          use Scope::Preview, site
          use Transaction, site
          use Authenticate::Init, site
          # Preview authentication redirects to /@spontaneous rather than
          # showing a login screen. This way if you go to the root of the site
          # as an unauthorised user (say for the first time) you will get sent
          # to the editing interface wrapper rather than being presented with
          # the preview site.
          use Authenticate::Preview
          use CSRF::Header
          use Spontaneous::Rack::Static, root: Spontaneous.root / 'public', urls: %w[/], try: ['.html', 'index.html', '/index.html']
          use Reloader, site
          # inject the front controllers into the preview so that this is a
          # full duplicate of the live site
          site.front.middleware.each do |args, block|
            use(*args, &block)
          end
          site.front_controllers.each do |namespace, controller_class|
            map namespace do
              run controller_class
            end
          end
          run Preview
        end
      end

      def self.application(site = ::Spontaneous.instance)
        ::Rack::Builder.new do
          site.back_controllers.each do |namespace, controller|
            map(namespace) do
              use Scope::Edit, site
              use Authenticate::Init, site
              use Authenticate::Edit
              use CSRF::Header
              use CSRF::Verification
              run controller
            end
          end

          # Make all the files available under plugin_name/public/**
          # available under the URL /plugin_name/**
          # This needs to be handled by the asset system
          # so that /assets/<plugin_name>/file.css is properly found
          # and processed through sprockets
          site.plugins.each do |plugin|
            root = plugin.paths.expanded(:public)

            map "/#{plugin.file_namespace}" do
              use Spontaneous::Rack::CSS, root: root
              run ::Rack::File.new(root)
            end
          end if site

          map('/assets') { run SiteAssets.new }

          map '/media' do
            use ::Rack::Lint
            use Spontaneous::Rack::CacheableFile
            run ::Rack::File.new(Spontaneous.media_dir)
          end

          map(NAMESPACE) { run Spontaneous::Rack::Back.editing_app(site) }

          run Spontaneous::Rack::Back.preview_app(site)
        end
      end
    end
  end
end
