# encoding: UTF-8

module Spontaneous
  class Facet
    def initialize(root)
      @root = root
      paths.add :lib, ["lib", "**/*.rb"]
      paths.add :schema, ["schema", "**/*.rb"]
      paths.add :templates, "templates"
      paths.add :config, "config"
    end

    def paths
      @paths ||= Spontaneous::Paths.new(@root)
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
