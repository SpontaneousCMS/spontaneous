# Should be called *after* the revision
module Spontaneous::Publishing::Steps
  class WriteRevisionFile < BaseStep
    # This is now a no-op as the output store now handles this
    # as part of the ActivateRevision step

    def call
    end

    def count
      0
    end

    def rollback
    end
  end
end
