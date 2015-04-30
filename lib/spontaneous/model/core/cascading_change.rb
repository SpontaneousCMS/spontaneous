# encoding: UTF-8

module Spontaneous::Model::Core
  module CascadingChange
    extend Spontaneous::Concern

    module ClassMethods
      def split_materialised_path(mp, sep = Spontaneous::Model::ANCESTOR_SEP)
        mp.split(sep).map { |id| id.to_i }
      end

      def join_materialised_path(parts, sep = Spontaneous::Model::ANCESTOR_SEP)
        parts.reject(&:blank?).join(sep)
      end

      def cascading_change(attr_name, &block)
        define_method "#{attr_name}=" do |value|
          append_cascading_change(attr_name, self[attr_name], value, &block)
          super(value)
        end
      end
    end

    private

    def changes_to_cascade
      @changes_to_cascade ||= {}
    end

    def append_cascading_change(attribute, old_value, new_value, &block)
      changes_to_cascade[attribute] = block.call(self, old_value, new_value) if new_value != old_value
    end

    def after_save
      super
      cascade_all_changes
    end

    def cascade_all_changes
      changes_to_cascade.each do |attribute, propagator|
        propagator.propagate
      end
      changes_to_cascade.clear
    end
  end
end
