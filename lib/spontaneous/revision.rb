require 'pathname'

module Spontaneous
  class Revision
    attr_reader :revision, :site

    def initialize(revision, site)
      @revision = revision.to_i
      @site = site
    end

    def root
      ::File.join(site.revision_root, padded_revision)
    end

    def path(*path)
      path = path.flatten
      Pathname.new(File.join(root, *path.map(&:to_s)))
    end

    def padded_revision
      revision.to_s.rjust(5, "0")
    end

    def to_i
      @revision
    end
  end
end
