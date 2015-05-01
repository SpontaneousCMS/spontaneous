module Spontaneous::Publishing
  class Reindex < Publish
    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def reindex
      model.scope(revision, true) do
        pipeline.run(site, revision, [], progress)
      end
      progress.done
    end
  end
end
