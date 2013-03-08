require 'sprockets'

module Spontaneous::Asset
  module Environment
    def self.new(context)
      if context.publishing?
        Publish.new(context.site, context.revision)
      else
        Preview.new(context.site)
      end
    end

    def self.preview(site = Spontaneous::Site.instance)
      Preview.new(site)
    end

    module SassFunctions
      def asset_data_uri(path)
        Sass::Script::String.new(sprockets_context.asset_data_uri(path.value))
      end
    end

    ::Sass::Script::Functions.send :include, SassFunctions


    class Preview
      attr_reader :environment

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
            asset = environment[path]
            return path if asset.nil?
            make_absolute asset.logical_path
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
        assets  = paths.map { |path| environment[path] || path }
        assets.map { |asset| to_url(asset) }
      end

      def normalise_sources(sources, options)
        sources.map { |path| to_logical(path, options[:type]) }
      end

      def js(sources)
        find(sources, type: :js)
      end

      def css(sources)
        find(sources, type: :css)
      end

      def call(env)
        environment.call(env)
      end

      def to_url(asset)
        return asset if asset.is_a?(String)
        "/" << asset_mount_point << "/" << asset.logical_path
      end

      def asset_mount_point
        "assets"
      end

      ABSOLUTE_URL  = /^(https?:)?\/\//
      LEADING_SLASH = /^\/?([^\/].*)/ # Needs to avoid changing paths that start with //

      def is_absolute_url?(path)
        ABSOLUTE_URL === path
      end

      def to_logical(path, type)
        return path if is_absolute_url?(path)
        filename_with_extension(path[LEADING_SLASH, 1], type)
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
      def initialize(site, revision)
        super(site)
        @revision = Spontaneous.revision(revision)
        environment.css_compressor = :scss
        environment.js_compressor  = :uglifier
        environment.context_class.manifest = manifest
        environment.context_class.asset_mount_point = asset_mount_point
      end

      def manifest
        @manifest ||= Sprockets::Manifest.new(environment, manifest_file)
      end

      def manifest_file
        File.join(bundle_dir, "manifest.json")
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

      def bundle_dir
        @revision.path(asset_mount_point)
      end

      def to_url(asset)
        return nil if asset.nil?
        "/" << asset_mount_point << "/" << asset
      end

      def context_extension
        Proc.new {

          class << self
            attr_accessor :manifest, :asset_mount_point
          end

          # Too easy to be right
          def asset_path(path, options = {})
            manifest = self.class.manifest
            manifest.compile(path)
            asset = manifest.assets[path]
            return path if asset.nil?
            make_absolute asset
          end

          def make_absolute(logical)
            "/" << self.class.asset_mount_point << "/" << logical
          end
        }
      end
    end
  end
end
