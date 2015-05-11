module Spontaneous::Output::Store
  class Store
    def initialize(backing)
      @backing = backing
    end

    def revision(revision)
      Spontaneous::Output::Store::Revision.new(revision, @backing)
    end

    def revisions
      @backing.revisions
    end

    def current_revision
      @backing.current_revision
    end
  end
end
