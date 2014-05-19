# encoding: UTF-8


module Spontaneous::Model::Core
  module ContentHash
    extend Spontaneous::Concern

    class ContentHashChange
      def initialize(origin, old_value, new_value)
        @origin, @old_value, @new_value = origin, old_value, new_value
      end

      def propagate
        owner.recalculate_content_hash! if propagate_to_owner?
      end

      def propagate_to_owner?
        !owner.nil?
      end

      def owner
        @origin.owner
      end
    end

    included do
      cascading_change :content_hash, ContentHashChange
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
      recalculate_content_hash if mapper.editable?
      super
    end

    def recalculate_content_hash
      db, current, published = self[:content_hash], calculate_content_hash, published_content_hash
      changed = published.blank? || current != published
      self.update(content_hash: current, content_hash_changed: changed, content_hash_changed_at: ::Sequel.datetime_class.now) if db != current
    end

    # Recalculate the current content hash ensuring that we're taking all
    # content_hash values from the db not Used by content hash change
    # propagation -- without the #reload call existing cached versions of the
    # content tree may be used and changes will not propagate
    def recalculate_content_hash!
      reload unless modified?
      recalculate_content_hash
    end
  end
end
