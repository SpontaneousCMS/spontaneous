require 'sprockets'

module Spontaneous::Asset
  module Environment
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
        end

        def compile!(*args)
          @manifest.compile(*args)
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

          include RailsCompatibilityShim

          def make_absolute(logical)
            "/" << self.class.asset_mount_point << "/" << logical
          end
        end
      end
    end
  end
end
