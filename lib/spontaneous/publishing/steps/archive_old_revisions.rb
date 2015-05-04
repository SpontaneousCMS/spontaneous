module Spontaneous::Publishing::Steps
  class ArchiveOldRevisions < BaseStep
    KEEP_REVISIONS = 8

    def count
      1
    end

    def call
      progress.stage("archiving old revisions")
      site.model.cleanup_revisions(revision, keep_revisions)
      progress.step(1)
    end

    def rollback
    end

    def keep_revisions
      site.config.keep_revisions || KEEP_REVISIONS
    end
  end
end
