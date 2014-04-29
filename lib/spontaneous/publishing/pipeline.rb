module Spontaneous::Publishing
  class Pipeline
    attr_reader :steps

    def initialize(steps)
      @steps = Array(steps)
      @completed = []
    end

    def run(site, revision, pages, progress)
      calculate_step_count(site, revision, pages, progress)
      run_steps(site, revision, pages, progress)
    end

    def run_steps(site, revision, pages, progress)
      begin
        run_steps!(site, revision, pages, progress)
      rescue Exception => e
        rollback_steps!(site, revision, pages, progress)
        raise e
      end
    end

    def run_steps!(site, revision, pages, progress)
      steps.each do |step|
        @completed << step.call(site, revision, pages, progress)
      end
    end

    def rollback_steps!(site, revision, pages, progress)
      @completed.each do |step|
        step.rollback if step && step.respond_to?(:rollback)
      end
    end

    def calculate_step_count(site, revision, pages, progress)
      count = steps.map { |step|
        step.respond_to?(:count) ? step.count(site, revision, pages, progress) : 0
      }.inject(0, :+)
      progress.start(count)
    end
  end
end
