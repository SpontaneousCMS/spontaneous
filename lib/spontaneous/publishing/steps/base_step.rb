module Spontaneous::Publishing::Steps
  class BaseStep

    def self.to_sym
      name.demodulize.underscore.to_sym
    end

    def self.count(transaction)
      new(transaction).count
    end

    # create, run & return an instance that does the actual work
    def self.call(transaction)
      new(transaction).tap do |instance|
        begin
          instance.call
        rescue Exception => e
          instance.rollback #if instance.respond_to?(:rollback)
          raise
        end
      end
    end

    def self.inherited(subclass)
      Spontaneous::Publishing::Steps.register_step(subclass)
    end

    attr_reader :transaction

    def initialize(transaction)
      @transaction = transaction
    end

    def revision
      @transaction.revision
    end

    def site
      @transaction.site
    end

    def progress
      @transaction.progress
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
