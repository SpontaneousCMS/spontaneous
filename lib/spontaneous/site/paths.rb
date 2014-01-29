# encoding: UTF-8

class Spontaneous::Site
  module Paths
    extend Spontaneous::Concern

    def paths(*args)
      return _paths if args.empty?
      group = args.first
      facets.flat_map { |facet| facet._paths.expanded(group) }
    end
  end # Paths
end
