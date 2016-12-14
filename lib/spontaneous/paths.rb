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
      options = paths.extract_options!
      self[category].concat(paths)
      ensure_paths(paths) if options[:ensure]
    end

    def expanded(category)
      self[category].map do |path, glob|
        abs_path = expand_path(path)
        if abs_path.exist?
          abs_path += glob if glob
          abs_path.to_s
        else
          nil
        end
      end.compact
    end

    def ensure_paths(paths)
      paths.each do |path|
        expand_path(path).mkpath
      end
    end

    def expand_path(path)
      p = Pathname.new(path)
      p = Pathname.new(@root).join(p) unless (p.absolute? && p.exist?)
      if p.exist?
        p.cleanpath
      else
        p
      end
    end
  end # Paths
end # Spontaneous
