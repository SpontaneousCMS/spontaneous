module Spontaneous::Publishing
  class Rerender < Publish
    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def rerender
      pipeline.run(site, revision, [], progress)
    end

    def progress
      @progress ||= Progress::Stdout.new
    end
  end
end
