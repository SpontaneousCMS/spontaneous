# encoding: UTF-8

require 'fiber'

module Spontaneous::Plugins::Application
  module System
    extend Spontaneous::Concern

    module ClassMethods
      def async?
        defined?(::EM) && ::EM.reactor_running?
      end

      def system(cmd, timeout = 10, &callback)
        if async?
          async_system(cmd, &callback)
        else
          result = super(cmd)
          callback.call(result) if callback
        end
      end

      # Invokes an asynchronous system call
      def async_system(cmd, timeout = 10, &callback)
        deferrable = EM::DefaultDeferrable.new
        EM.system cmd do |output, status|
          deferrable.succeed(output, status)
        end
        deferrable.timeout timeout
        deferrable.errback {  }
        deferrable.callback(&callback)
      end
    end
  end
end
