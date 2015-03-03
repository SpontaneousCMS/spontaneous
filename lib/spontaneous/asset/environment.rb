require 'sprockets'
require 'uri'

module Spontaneous::Asset
  module Environment
    def self.new(context)
      if context.publishing?
        publishing(context.site, context.revision, context.development?)
      else
        preview(context.site)
      end
    end

    def self.publishing(site, revision, development)
      Publish.new(site, revision, development)
    end

    def self.preview(site = Spontaneous::Site.instance)
      Preview.new(site)
    end

    # takes a path that has optional hash & query parts and splits
    # out the real asset path.
    def self.split_asset_path(path)
      uri = URI(path)
      [uri.path, uri.query, uri.fragment]
    end


    # takes a path that has optional hash & query parts and splits
    # out the real asset path.
    def self.join_asset_path(path, query, hash)
      joined = path.dup
      joined << "?#{query}" if query
      joined << "##{hash}"  if hash
      joined
    end

    module SassFunctions
      def asset_data_uri(path)
        uri = sprockets_context.asset_data_uri(path.value)
        Sass::Script::String.new("url(#{uri})")
      end
    end

    ::Sass::Script::Functions.send :include, SassFunctions


    class Preview
      attr_reader :environment, :site

      def initialize(site)
        @site = site
        asset_paths.each do |path|
          environment.append_path(path)
        end
      end

      def asset_paths
        @site.paths.expanded(:assets)
      end

      def environment
        @environment ||= build_environment(@site)
      end

      def build_environment(site)
        environment = ::Sprockets::Environment.new(site.root)
        environment.context_class.class_eval(&context_extension)
        environment.context_class.asset_mount_point = asset_mount_point
        environment
      end

      def context_extension
        proc {
          class << self
            attr_accessor :asset_mount_point
          end

          def asset_path(path, options = {})
            asset_path, query, fragment = Spontaneous::Asset::Environment.split_asset_path(path)
            asset = environment[asset_path]
            return path if asset.nil?
            Spontaneous::Asset::Environment.join_asset_path(make_absolute(asset.logical_path), query, fragment)
          end

          def make_absolute(logical)
            "/" << self.class.asset_mount_point << "/" << logical
          end
        }
      end

      # The preview environment converts logical paths to a list of URLs
      #
      # Because I want to support using absolute paths in my asset lists
      # I have to convert from URL paths to relative paths first to avoid
      # confusing sprockets (which treats a path starting with / as an
      # absolute file path and will fail to locate assets that have one.)
      #
      #   - sources: a list of `logical paths`
      #   - options:
      #     - :type => either :js or :css
      #
      # Returns a list of URLs
      def find(sources, options)
        paths   = normalise_sources(sources, options)
        if options[:development]
          assets = paths.flat_map { |path| a = environment[path, bundle: true].to_a ; a.empty? ? [path] : a }
        else
          assets = paths.map { |path| environment[path] || path }
        end
        assets.map { |asset| to_url(asset, options[:development]) }
      end

      def normalise_sources(sources, options)
        Array(sources).map { |path| to_logical(path, options[:type]) }
      end

      def js(sources, options = {})
        find(sources, options.merge(type: :js))
      end

      def css(sources, options = {})
        find(sources, options.merge(type: :css))
      end

      def call(env)
        environment.call(env)
      end

      def to_url(asset, body = false)
        return asset if asset.is_a?(String)
        query = {}
        query['body'] = 1 if body
        query[asset.digest] = nil if dynamic_fingerprint?
        path = asset.logical_path
        path = "#{path}?#{Rack::Utils.build_query(query)}" unless query.empty?
        "/" << asset_mount_point << "/" << path
      end

      # include the asset fingerprint as a query param for cache busting
      def dynamic_fingerprint?
        true
      end

      def asset_mount_point
        "assets"
      end

      ABSOLUTE_URL  = /^(https?:)?\/\//

      def is_absolute_url?(path)
        ABSOLUTE_URL === path
      end

      def to_logical(path, type)
        return path if is_absolute_url?(path)
        filename_with_extension(path, type)
      end

      EXTENSIONS = {
        js: ".js",
        javascript: ".js",
        css: ".css",
        stylesheet: ".css"
      }

      def filename_with_extension(base, type)
        ext = EXTENSIONS[type]
        return base if File.extname(base) == ext
        "#{base}#{ext}"
      end
    end

    class Publish < Preview
      def initialize(site, revision, development)
        super(site)
        @revision = site.revision(revision)
        @development = development
        # environment.logger = Logger.new($stdout)
        environment.css_compressor = :scss
        environment.js_compressor  = :uglifier
        environment.context_class.manifest = manifest
        environment.context_class.asset_mount_point = asset_mount_point
      end

      def development?
        @development || false
      end

      # include the asset fingerprint as a query param for cache busting
      def dynamic_fingerprint?
        false
      end

      # A proxy to the sprockets manifest that compiles assets on the first run
      # then re-uses them on the second
      class Manifest
        def initialize(environment, revision, development)
          @environment = environment
          @revision = revision
          @development = development || false
          @manifest = Sprockets::Manifest.new(environment.environment, manifest_file)
        end

        def development?
          @development
        end

        def manifest_file
          File.join(asset_compilation_dir, "manifest.json")
        end

        def assets
          @manifest.assets
        end

        def compile(*args)
          assets = @manifest.assets
          unless (args.all? { |key| assets.key?(key) })
            compile!(*args)
          end
          copy_assets_to_revision(args)
        end

        def compile!(*args)
          @manifest.compile(*args)
          copy_assets_to_revision(args)
        end

        def copy_assets_to_revision(logical_paths)
          assets = @manifest.assets
          paths = logical_paths.map { |a| assets[a] }.compact
          source, dest = shared_asset_dir, revision_asset_dir
          paths.each do |asset|
            copy_asset_to_revision(source, dest, asset)
          end
        end

        def copy_asset_to_revision(source, dest, asset)
          to = dest + asset
          return if to.exist?
          from = source + asset
          to.dirname.mkpath
          FileUtils.cp(from, to)
        end

        def asset_compilation_dir
          development? ? revision_asset_dir : shared_asset_dir
        end

        def revision_asset_dir
          @revision.path(@environment.asset_mount_point)
        end

        def shared_asset_dir
          @environment.site.path!('assets/tmp')
        end
      end

      def manifest
        @manifest ||= Manifest.new(self, @revision, development?)
      end

      def find(sources, options)
        paths   = normalise_sources(sources, options)
        paths   = paths.each_with_index.map { |p, i| [p, i] }
        remote, local = paths.partition { |p, i| is_absolute_url?(p) }
        manifest.compile(*local.map(&:first))
        assets  = local.map { |p, i| [manifest.assets[p], i]}
        assets  = assets.map { |asset, i| [to_url(asset), i] }
        # Pass through any sources that don't exist
        assets  = assets.map { |p, i| p.nil? ? [sources[i], i] : [p, i] }
        assets.concat(remote).sort { |a, b| a[1] <=> b[1] }.map(&:first)
      end

      def to_url(asset)
        return nil if asset.nil?
        "/" << asset_mount_point << "/" << asset
      end

      def context_extension
        Proc.new do
          class << self
            attr_accessor :manifest, :asset_mount_point
          end

          # Too easy to be right
          def asset_path(path, options = {})
            asset_path, query, fragment = Spontaneous::Asset::Environment.split_asset_path(path)
            manifest = self.class.manifest
            manifest.compile(asset_path)
            asset = manifest.assets[asset_path]
            return path if asset.nil?
            Spontaneous::Asset::Environment.join_asset_path(make_absolute(asset), query, fragment)
          end

          def make_absolute(logical)
            "/" << self.class.asset_mount_point << "/" << logical
          end
        end
      end
    end
  end
end
