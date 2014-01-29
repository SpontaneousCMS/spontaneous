module Spontaneous::Storage::Template
  class Store
    def initialize(backing)
      @backing = backing
    end

    def revision(revision)
      Spontaneous::Storage::Template::Revision.new(revision, @backing)
    end

    def revisions
      @backing.revisions
    end
  end
end