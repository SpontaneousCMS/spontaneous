module Spontaneous::Publishing
  class Pipeline
    attr_reader :steps

    def initialize(steps)
      @steps = Array(steps)
      @completed = []
    end

    def run(transaction)
      calculate_step_count(transaction)
      run_steps(transaction)
    end

    def run_steps(transaction)
      begin
        run_steps!(transaction)
      rescue Exception => e
        rollback_steps!(transaction)
        raise
      end
    end

    def run_steps!(transaction)
      steps.each do |step|
        @completed << step.call(transaction)
      end
    end

    def rollback_steps!(transaction)
      @completed.each do |step|
        step.rollback if step && step.respond_to?(:rollback)
      end
    end

    def calculate_step_count(transaction)
      count = steps.map { |step|
        step.respond_to?(:count) ? step.count(transaction) : 0
      }.inject(0, :+)
      transaction.progress.start(count)
    end
  end
end
