# encoding: UTF-8

require 'pathname'

module Spontaneous
  class Paths < ::Hash
    # TODO: Move this kind of stuff into the Revision class
    # Instead of throwing around revision numbers we should
    # be throwing around Revision instances. It is fecking OO
    # after all...
    def self.pad_revision_number(revision)
      revision.to_s.rjust(5, "0")
    end

    def initialize(root)
      @root = File.expand_path(root)
      super() { |hash, key| hash[key] = [] }
    end

    def add(category, *paths)
      self[category].concat(paths)
    end

    def expanded(category)
      self[category].map do |path, glob|
        path = Pathname.new(path)
        path = Pathname.new(@root) + path unless (path.absolute? && path.exist?)
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
