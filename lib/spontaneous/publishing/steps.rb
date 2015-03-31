
module Spontaneous::Publishing
  module Steps
    class InvalidStepException < Spontaneous::Error
      def initialize(step)
        super("Unknown/invalid step #{step.inspect}")
      end
    end
    class InvalidProgressException < Spontaneous::Error
      def initialize(progress)
        super("Unknown/invalid progress #{progress.inspect}")
      end
    end

    def self.new(steps = [], progress = [], &block)
      Steps.new(steps, progress, &block)
    end

    def self.minimal
      new do
        run :activate_revision
      end
    end

    def self.rerender(publishing_steps)
      new([], publishing_steps.progress) do
        RERENDER_STEPS.each do |step|
          run step
        end
      end
    end

    def self.reindex(publishing_steps)
      new([], publishing_steps.progress) do
        REINDEX_STEPS.each do |step|
          run step
        end
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
        instance_eval(&block) if block
      end

      def notify(progress, *args)
        @steps.add_progress(validate_progress(make_progress(progress, args)))
      end

      alias_method :log, :notify

      def run(step)
        @steps.add_step(validate_step(make_step(step)))
      end

      def validate_progress(progress)
        raise InvalidProgressException.new(progress) unless progress && is_progress?(progress)
        progress
      end

      def make_progress(progress, args)
        return progress if is_progress?(progress)
        progress_class = case progress
        when Symbol
          Spontaneous::Publishing::Progress.retrieve(progress)
        else
          raise InvalidProgressException.new(progress)
        end
        return nil if progress_class.nil?
        progress_class.new(*args)
      end

      def is_progress?(obj)
        [:start, :stage, :step, :log, :done].all? { |method| obj.respond_to?(method) }
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
      attr_reader :steps, :progress

      def initialize(steps = [], progress = [], &block)
        @steps, @progress = steps, progress
        DSL.new(self, &block)
      end

      def add_progress(reporter)
        progress << reporter
      end

      def add_step(step)
        steps << step
      end

      def run(transaction)
        @steps.each do |step|
          progress.add(step.count(transaction)) if step.respond_to?(:count)
        end

        @steps.each do |step|
          step.call(transaction)
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
      :copy_assets,
      :copy_static_files,
      :generate_rackup_file,
      :activate_revision,
      :archive_old_revisions
    ].freeze

    RERENDER_STEPS = [
      :render_revision,
      :copy_assets,
      :copy_static_files,
      :generate_rackup_file,
      :activate_revision
    ].freeze

    REINDEX_STEPS = [
      :generate_search_indexes,
    ].freeze

    CORE_PROGRESS = [:browser, :stdout].freeze
  end
end

require 'spontaneous/publishing/steps/base_step'
require 'spontaneous/publishing/steps/create_revision_directory'
require 'spontaneous/publishing/steps/render_revision'
require 'spontaneous/publishing/steps/generate_search_indexes'
require 'spontaneous/publishing/steps/copy_static_files'
require 'spontaneous/publishing/steps/copy_assets'
require 'spontaneous/publishing/steps/generate_rackup_file'
require 'spontaneous/publishing/steps/activate_revision'
require 'spontaneous/publishing/steps/write_revision_file'
require 'spontaneous/publishing/steps/archive_old_revisions'
