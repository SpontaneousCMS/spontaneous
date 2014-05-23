# encoding: UTF-8


module Spontaneous::Model::Core
  module ContentHash
    extend Spontaneous::Concern

    class ContentHashChange
      def initialize(origin)
        @origin = origin
      end

      def propagate
        content = owner
        while propagate_to?(content)# && content.modification_tracking_enabled?
          content.recalculate_content_hash!# if propagate_to_owner?
          content = content.owner
        end
      end

      def propagate_to?(content)
        !(content.nil? || (@origin.page? && content.page?)) && content.modification_tracking_enabled?
      end

      def owner
        @origin.owner
      end
    end

    included do
      cascading_change :content_hash do |origin, old_value, new_value|
        ContentHashChange.new(origin)
      end
    end

    def content_hash_changed?
      content_hash_changed
    end

    def content_hash
      super || calculate_content_hash
    end

    def calculate_content_hash
      Spontaneous::Model.content_hash(content_hash_dependencies { |el| el.content_hash })
    end

    def calculate_content_hash!
      Spontaneous::Model.content_hash(content_hash_dependencies { |el| el.calculate_content_hash! })
    end

    def content_hash_dependencies(&calculation)
      fields = fields_with_consistent_order.map(&calculation)
      boxes = boxes_with_consistent_order.reject(&:generated?).map(&calculation)
      [schema_id, hidden].concat(fields).concat(boxes)
    end

    def after_save
      # Only recalculate the content hash if we're in the editable dataset, otherwise
      # the published data can end up with a different content hash even after being published
      recalculate_content_hash if modification_tracking_enabled?
      enable_modification_tracking
      super
    end

    def recalculate_content_hash
      attrs, changed = content_hash_attributes
      self.update(attrs) if changed
    end

    # Update the instances content hash by writing direct to the db & without triggering any futher cascading changes
    # Without the #reload call existing cached versions of the
    # content tree may be used and changes will not propagate
    def recalculate_content_hash!
      reload unless modified?
      attrs, changed = content_hash_attributes
      model.where(id: id).update(attrs) if changed
    end

    def content_hash_attributes
      db, current, published = self[:content_hash], calculate_content_hash, published_content_hash
      changed = published.blank? || current != published
      [{content_hash: current, content_hash_changed: changed, content_hash_changed_at: ::Sequel.datetime_class.now}, db != current]
    end

    def modification_tracking_enabled?
      mapper.editable? && !@modification_tracking_disabled
    end

    def disable_modification_tracking!
      @modification_tracking_disabled = true
    end

    def enable_modification_tracking
      @modification_tracking_disabled = false
    end
  end
end
