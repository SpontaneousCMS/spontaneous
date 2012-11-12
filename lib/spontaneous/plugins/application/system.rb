# encoding: UTF-8

require 'fiber'

module Spontaneous::Plugins::Application
  module System
    extend Spontaneous::Concern

    module ClassMethods
      def async?
        defined?(::EM) && ::EM.reactor_running?
      end

      def system(cmd, timeout = 10)
        return async_system(cmd) if async?
        super(cmd)
      end

      # Invokes an asynchronous system call. Must be wrapped in a Fiber
      # such as that provided by rack-fiber_pool
      def async_system(cmd, timeout = 10)
        deferrable = EM::DefaultDeferrable.new
        fiber = Fiber.current
        EM.system cmd do |output, status|
          deferrable.succeed
          fiber.resume [output, status]
        end
        deferrable.timeout timeout
        deferrable.errback {  }
        output, status = Fiber.yield
        status.success?
      end
    end
  end
end
