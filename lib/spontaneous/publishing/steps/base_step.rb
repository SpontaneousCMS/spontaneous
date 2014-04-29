module Spontaneous::Publishing::Steps
  class BaseStep

    def self.to_sym
      name.demodulize.underscore.to_sym
    end

    def self.count(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new)
      new(site, revision, pages, progress).count
    end

    # create, run & return an instance that does the actual work
    def self.call(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new)
      new(site, revision, pages, progress).tap do |instance|
        instance.call
      end
    end

    def self.inherited(subclass)
      Spontaneous::Publishing::Steps.register_step(subclass)
    end

    attr_reader :revision, :site, :progress

    def initialize(site, revision, pages, progress)
      @site, @revision, @pages, @progress = site, revision, pages, progress
    end

    # Does the actual work
    def call
      # implement in subclasses
    end

    # Should return the number of steps we're going to make
    def count
      # implement in subclasses
    end

    # Undo what we did in #call in case of exceptions
    def rollback
      # implement in subclasses
    end
  end
end
