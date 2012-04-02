
module Spontaneous::Plugins::Site
  module Hooks
    extend ActiveSupport::Concern

    HOOKS = [:after_publish]

    module ClassMethods
      HOOKS.each do |hook|
        # def after_publish(&block)
        #   instance.after_publish(&block)
        # end
        class_eval(<<-RB)
          def #{hook}(&block)
            instance.#{hook}(&block)
          end
        RB
      end

      def trigger(event_name, *args)
        instance.trigger(event_name, *args)
      end
    end

    HOOKS.each do |hook|
      # def after_publish(&block)
      #   add_trigger(:after_publish, block)
      # end
      class_eval(<<-RB)
        def #{hook}(&block)
          add_trigger(:#{hook}, block)
        end
      RB
    end

    def triggers
      @triggers ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def add_trigger(trigger_name, block)
      triggers[trigger_name] << block
    end

    def trigger(event_name, *args)
      triggers[event_name].each do |block|
        block.call(*args)
      end
    end
  end
end
