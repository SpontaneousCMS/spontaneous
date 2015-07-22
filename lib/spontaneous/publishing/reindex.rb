module Spontaneous::Publishing
  class Reindex < Publish
    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def reindex
      model.scope(revision, true) do
        pipeline.run(transaction([], nil))
      end
      progress.done
    end
  end
end
