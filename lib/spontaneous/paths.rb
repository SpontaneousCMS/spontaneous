# encoding: UTF-8

require 'pathname'

module Spontaneous
  class Paths < ::Hash
    def initialize(root)
      @root = File.expand_path(root)
      super()
    end

    def add(category, *paths)
      self[category] = paths
    end

    def expanded(category)
      self[category].map do |path, glob|
        path = Pathname.new(@root) + path
        if path.exist?
          path = path.cleanpath
          path += glob if glob
          path.to_s
        else
          nil
        end
      end.compact
    end
  end # Paths
end # Spontaneous
