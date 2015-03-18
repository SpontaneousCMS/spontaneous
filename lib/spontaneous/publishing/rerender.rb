module Spontaneous::Publishing
  class Rerender < Publish
    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def rerender
      model.scope(revision, true) do
        pipeline.run(site, revision, [], progress)
      end
      progress.done
    end
  end
end
