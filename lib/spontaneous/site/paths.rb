# encoding: UTF-8

class Spontaneous::Site
  module Paths
    extend Spontaneous::Concern

    module ClassMethods
      def paths(group)
        instance.facets.flat_map { |facet| facet.paths.expanded(group) }
      end
    end # ClassMethods
  end # Paths
end
