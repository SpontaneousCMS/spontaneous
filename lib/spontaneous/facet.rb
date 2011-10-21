# encoding: UTF-8

module Spontaneous
  class Facet

    def initialize(root)
      @root = File.expand_path(root)
      paths.add :lib, ["lib", "**/*.rb"]
      paths.add :schema, ["schema", "**/*.rb"]
      paths.add :templates, "templates"
      paths.add :config, "config"
      paths.add :public, "public"
      paths.add :tasks, ["lib/tasks", "**/*.rake"]
      paths.add :migrations, ["db/migrations", "**/*.rake"]
      paths.add :plugins, ["plugins", "*"]
      paths.add :features, "features"
    end


    def root(*path)
      return @root if path.empty?
      File.join(@root, path)
    end

    def name
      File.basename(root)
    end

    # used by publishing mechanism to place files into the appropriate subdirectories
    # in the public folder.
    def file_namespace
      name
    end

    def paths
      @paths ||= Spontaneous::Paths.new(@root)
    end

    def config
      Site.instance.config
    end

    def load_config!
      paths.expanded(:config).each do |config_path|
        Site.config.load(config_path)
      end
    end

    def load_indexes!
      paths.expanded(:config).each do |config_path|
        index_file = config_path / "indexes.rb"
        load(index_file) if File.exists?(index_file)
      end
    end

    def init!
    end

    def load!
      Spontaneous::Loader.load_classes(load_paths)
    end

    def load_paths
      load_paths = []
      [:lib, :schema].each do |category|
        load_paths += paths.expanded(category)
      end
      load_paths
    end

  end # Facet
end # Spontaneous
