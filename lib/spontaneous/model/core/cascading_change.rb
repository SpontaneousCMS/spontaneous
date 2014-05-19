# encoding: UTF-8

module Spontaneous::Model::Core
  module CascadingChange
    extend Spontaneous::Concern

    module ClassMethods
      def cascading_change(attr_name, change_propagator_class)
        define_method "#{attr_name}=" do |value|
          append_cascading_change(change_propagator_class, self[attr_name], value)
          super(value)
        end
      end
    end

    private

    def changes_to_cascade
      @changes_to_cascade ||= []
    end

    def append_cascading_change(change_propagator_class, old_value, new_value)
      changes_to_cascade << change_propagator_class.new(self, old_value, new_value) if new_value != old_value
    end

    def after_save
      super
      cascade_all_changes
    end

    def cascade_all_changes
      changes_to_cascade.each do |propagator|
        propagator.propagate
      end
      changes_to_cascade.clear
    end
  end
end
