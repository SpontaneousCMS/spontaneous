# encoding: UTF-8

module Spontaneous
  module Application
    class Instance < Spontaneous::Facet
      def initialize!
        Spontaneous.facets.each do |facet|
          load_facet_code(facet)
          load_facet_config(facet)
        end
      end

      def load_facet_code(facet)
        facet.load!
      end

      def load_facet_config(facet)
        facet.paths.expanded(:config).each do |config_path|
          Spontaneous.config.load(config_path)
        end
      end
    end # Instance
  end # Application
end # Spontaneous
