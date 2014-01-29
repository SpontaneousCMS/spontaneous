# encoding: UTF-8

class Spontaneous::Site
  module State
    extend Spontaneous::Concern

    def working_revision
      Spontaneous::State.revision
    end

    def revision
      Spontaneous::State.revision
    end

    def published_revision
      Spontaneous::State.published_revision
    end

    def pending_revision
      Spontaneous::State.pending_revision
    end

    def modified_at
      Spontaneous::State.modified_at
    end

    def must_publish_all?
      Spontaneous::State.must_publish_all?
    end

    def must_publish_all!(state = true)
      Spontaneous::State.must_publish_all!(state)
    end

    def revision_root(*path)
      instance.revision_root(*path)
    end

    def revision_dir(revision=nil, root = nil)
      instance.revision_dir(revision, root)
    end
  end
end
