require 'sprockets'

module Spontaneous::Asset
  module Environment
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
        Proc.new do
          class << self
            attr_accessor :asset_mount_point
          end

          def asset_path(path, options = {})
            asset_path, query, fragment = Spontaneous::Asset::Environment.split_asset_path(path)
            asset = environment[asset_path]
            return path if asset.nil?
            Spontaneous::Asset::Environment.join_asset_path(make_absolute(asset.logical_path), query, fragment)
          end

          include RailsCompatibilityShim

          def make_absolute(logical)
            "/" << self.class.asset_mount_point << "/" << logical
          end
        end
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
  end
end
