
module Spontaneous::Publishing
  module Steps
    class InvalidStepException < Spontaneous::Error
      def initialize(step)
        super("Unknown/invalid step #{step.inspect}")
      end
    end

    def self.new(&block)
      Steps.new(&block)
    end

    def self.minimal
      new do
        run :activate_revision
      end
    end

    def self.default
      new do
        CORE_STEPS.each do |step|
          run step
        end
      end
    end

    def self.register_step(step_class)
      registered_steps[step_class.to_sym] = step_class
    end

    def self.registered_steps
      @registered_steps ||= {}
    end

    class DSL
      def initialize(steps, &block)
        @steps = steps
        instance_eval(&block)
      end

      def run(step)
        @steps.push(validate_step(make_step(step)))
      end

      def validate_step(step)
        raise InvalidStepException.new(step) unless step && step.respond_to?(:call)
        step
      end

      def make_step(step)
        return step if step.respond_to?(:call)
        case step
        when Symbol
          Spontaneous::Publishing::Steps.registered_steps[step]
        else
          raise InvalidStepException.new(step)
        end
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

    CORE_STEPS = [
      :create_revision_directory,
      :render_revision,
      :generate_search_indexes,
      :copy_static_files,
      :generate_rackup_file,
      :activate_revision,
      :write_revision_file,
      :archive_old_revisions
    ].freeze
  end
end

require 'spontaneous/publishing/steps/base_step'
require 'spontaneous/publishing/steps/create_revision_directory'
require 'spontaneous/publishing/steps/render_revision'
require 'spontaneous/publishing/steps/generate_search_indexes'
require 'spontaneous/publishing/steps/copy_static_files'
require 'spontaneous/publishing/steps/generate_rackup_file'
require 'spontaneous/publishing/steps/activate_revision'
require 'spontaneous/publishing/steps/write_revision_file'
require 'spontaneous/publishing/steps/archive_old_revisions'
