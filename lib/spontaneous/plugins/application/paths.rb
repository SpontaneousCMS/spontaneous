# encoding: UTF-8

module Spontaneous::Plugins::Application
  module Paths
    extend ActiveSupport::Concern

    module ClassMethods
      def load_paths
        Spontaneous.instance.load_paths
      end

      def template_paths
        paths = []
        Spontaneous.facets.each do |facet|
          paths += facet.paths.expanded(:templates)
        end
        paths
      end

      def log_dir(*path)
        relative_dir(root / "log", *path)
      end

      def config_dir(*path)
        relative_dir(root / "config", *path)
      end

      # def template_root=(template_root)
      #   Spot::Render.template_root = template_root.nil? ? nil : File.expand_path(template_root)
      # end

      def template_root(*path)
        relative_dir(Spot::Render.template_root, *path)
      end

      def template_path(*args)
        File.join(template_root, *args)
      end

      def schema_root=(schema_root)
        @schema_root = schema_root
      end

      def schema_root(*path)
        @schema_root ||= root / "schema"
        relative_dir(@schema_root, *path)
      end

      def schema_map
        Spontaneous.schema.schema_map_file
      end

      def schema_map=(path)
        Spontaneous.schema.schema_map_file = path
      end

      # def media_dir=(dir)
      #   @media_dir = File.expand_path(dir)
      # end

      def media_dir(*path)
        Spontaneous.instance.media_dir(*path)
      end

      def media_path(*args)
        Spontaneous::Media.media_path(*args)
      end

      def cache_dir(*path)
        Spontaneous.instance.cache_dir(*path)
      end

      def shard_path(hash=nil)
        if hash
          path = ['tmp', hash[0..1], hash[2..3], hash]
          Spontaneous::Media.media_path(*path).tap do |path|
            ::FileUtils.mkdir_p(::File.dirname(path))
          end
        else
          Spontaneous::Media.media_path('tmp')
        end
      end

      def root(*path)
        Spontaneous.instance.root(*path)
      end

      # def root=(root)
      #   @root = File.expand_path(root)
      # end

      def revision_root(*path)
        Spontaneous.instance.revision_root(*path)
      end

      # def revision_root=(revision_dir)
      #   @revision_dir = File.expand_path(revision_dir)
      # end

      def revision_dir(revision=nil, root = nil)
        Spontaneous.instance.revision_dir(revision, root)
      end

      def gem_dir(*path)
        relative_dir(Spontaneous.gem_root, *path)
      end

      def application_dir(*path)
        @application_dir ||= File.expand_path("application", Spontaneous.gem_root)
        relative_dir(@application_dir, *path)
      end

      def static_dir(*path)
        application_dir / "static"
        relative_dir(application_dir / "static", *path)
      end

      def js_dir(*path)
        relative_dir(application_dir / "js", *path)
      end

      def css_dir(*path)
        relative_dir(application_dir / "css", *path)
      end

      def relative_dir(root, *path)
        File.join(root, *path.map { |p| p.to_s })
      end
    end # ClassMethods
  end # Paths
end
