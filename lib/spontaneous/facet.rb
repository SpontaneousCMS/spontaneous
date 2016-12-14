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
      paths.add :assets, "assets"
      paths.add :compiled_assets, "private/assets", ensure: true
      paths.add :tasks, ["lib/tasks", "**/*.rake"]
      paths.add :migrations, ["db/migrations", "**/*.rake"]
      paths.add :plugins, ["plugins", "*"]
      paths.add :features, "features"
    end


    def root(*path)
      return @root if path.empty?
      File.join(@root, path)
    end

    def path(*args)
      Pathname.new(@root).join(*args)
    end

    def path!(*args)
      self.path(*args).tap do |path|
        path.mkpath
      end
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
      _paths
    end

    def _paths
      @paths ||= Spontaneous::Paths.new(@root)
    end

    def config
      Spontaneous::Site.instance.config
    end

    def load_config!
      paths.expanded(:config).each do |config_path|
        Spontaneous::Site.config.load(config_path)
      end
    end

    # use Rails' alphabetical load order for initializers
    def run_initializers
      paths.expanded(:config).each do |config_path|
        Dir["#{config_path / "initializers"}/*.rb"].sort.each do |initializer|
          require initializer
        end
      end
    end

    def init!
    end

    def load!
      load_order.each { |category| load_files(category) }
    end

    def load_files(category)
      loaders[category].load!
    end


    def reload_all!
      load_order.each { |category| loaders[category].reload! }
    end
    alias_method :reload!, :reload_all!

    def load_order
      [:lib, :schema]
    end

    def loaders
      @loaders ||= \
      begin
        use_reloader = config.reload_classes
        {:schema => Spontaneous::SchemaLoader.new(schema_load_paths, use_reloader),
         :lib => Spontaneous::Loader.new(load_paths, use_reloader) }
      end
    end

    def load_paths
      load_paths_for_category(:lib)
    end

    def schema_load_paths
      load_paths_for_category(:schema)
    end

    def load_paths_for_category(category)
      self.paths.expanded(category)
    end

  end # Facet
end # Spontaneous
