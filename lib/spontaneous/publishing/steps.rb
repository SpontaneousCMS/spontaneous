
module Spontaneous::Publishing
  module Steps
    def self.new(&block)
      Steps.new(&block)
    end

    class DSL
      def initialize(steps, &block)
        @steps = steps
        instance_eval(&block)
      end

      def run(step)
        @steps.push(step)
      end
    end

    class Steps
      def initialize(&block)
        DSL.new(self, &block)
      end

      def steps
        @steps ||= []
      end

      def push(step)
        steps << step
      end

      def run(site, revision, pages, progress)
        @steps.each do |step|
          progress.add(step.count(site, revision)) if step.respond_to?(:count)
        end

        @steps.each do |step|
          step.call(site, revision, pages, progress)
        end
      end

      def to_a
        steps
      end
    end

    class BaseStep
      def self.count(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new)
        new(site, revision, pages, progress).count
      end

      # create, run & return an instance that does the actual work
      def self.call(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new)
        new(site, revision, pages, progress).tap do |instance|
          instance.call
        end
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
end

require 'spontaneous/publishing/steps/render_revision'
require 'spontaneous/publishing/steps/generate_search_indexes'
require 'spontaneous/publishing/steps/copy_static_files'
require 'spontaneous/publishing/steps/generate_rackup_file'
require 'spontaneous/publishing/steps/write_revision_file'
require 'spontaneous/publishing/steps/create_revision_directory'
require 'spontaneous/publishing/steps/activate_revision'
require 'spontaneous/publishing/steps/archive_old_revisions'
