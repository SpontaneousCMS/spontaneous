require 'pathname'

module Spontaneous
  class Revision
    attr_reader :revision

    def initialize(revision)
      @revision = revision.to_i
    end

    def root
      ::File.join(Spontaneous::Site.instance.revision_root, padded_revision)
    end

    def path(*path)
      path = path.flatten
      Pathname.new(File.join(root, *path.map(&:to_s)))
    end

    def padded_revision
      Spontaneous::Paths.pad_revision_number(revision)
    end

    def to_i
      @revision
    end

    module GlobalMethods
      def revision(revision)
        Revision.new(revision)
      end
    end
  end
end
