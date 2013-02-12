module Spontaneous
  module DataMapper
    module ContentModel
      module InstanceHooks
        # This only currently supports the after_save hooks as that's the
        # only one that's used (by PagePieces to save their owner after
        # a style change)
        def after_save_hook(&block)
          add_instance_hook(:after_save, &block)
        end

        def after_save
          run_after_instance_hooks(:after_save)
          super
        end

        private

        def add_instance_hook(hook, &block)
          instance_hooks(hook).push(block)
        end

        def instance_hooks(hook)
          @instance_hooks ||= {}
          @instance_hooks[hook] ||= []
        end

        def run_after_instance_hooks(hook)
          instance_hooks(hook).each{|b| b.call}
        end
      end
    end
  end
end
