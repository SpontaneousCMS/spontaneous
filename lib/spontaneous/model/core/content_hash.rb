# encoding: UTF-8

require 'digest/md5'

module Spontaneous::Model::Core
  module ContentHash
    extend Spontaneous::Concern

    def self.calculate(*values)
      values = Array(values).flatten
      md5 = Digest::MD5.new
      values.each do |value|
        md5.update(value.to_s)
      end
      md5.hexdigest
    end

    class ContentHashChange
      def initialize(origin)
        @origin = origin
      end

      def propagate
        content = owner
        while propagate_to?(content)# && content.modification_tracking_enabled?
          content.recalculate_content_hash!# if propagate_to_owner?
          break if content == @origin.page
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
      Spontaneous::Model::Core::ContentHash.calculate(content_hash_dependencies { |el| el.content_hash })
    end

    def calculate_content_hash!
      Spontaneous::Model::Core::ContentHash.calculate(content_hash_dependencies { |el| el.calculate_content_hash! })
    end

    def content_hash_dependencies(&calculation)
      fields = fields_with_consistent_order.map(&calculation)
      boxes = boxes_with_consistent_order.reject(&:generated?).map(&calculation)
      content_hash_columns.concat(fields).concat(boxes)
    end

    def content_hash_columns
      [schema_id, hidden?, target_id, owner_id, touched_at]
    end

    def before_save
      # Only recalculate the content hash if we're in the editable dataset, otherwise
      # the published data can end up with a different content hash even after being published
      recalculate_content_hash if modification_tracking_enabled?
      super
      true
    end

    def recalculate_content_hash
      attrs, changed = content_hash_attributes
      set(attrs) if changed
    end

    # Update the instances content hash by writing direct to the db & without
    # triggering any futher cascading changes. Without the #reload call
    # existing cached versions of the content tree may be used and changes
    # will not propagate
    def recalculate_content_hash!
      attrs, changed = content_hash_attributes
      model.where(id: id).update(attrs) if changed
    end

    def content_hash_attributes
      db, current, published = self[:content_hash], calculate_content_hash, published_content_hash
      changed = published.blank? || current != published
      [{content_hash: current, content_hash_changed: changed, content_hash_changed_at: ::Sequel.datetime_class.now}, db != current]
    end

    def modification_tracking_enabled?
      mapper.editable? #&& !@modification_tracking_disabled
    end

    module PageMethods
      # Make page modification state depend on its path
      def content_hash_dependencies
        super.push(slug)
      end
    end

    module BoxMethods
      def generated?
        _prototype.generated?
      end

      def content_hash
        _content_hash { |el| el.content_hash }
      end

      # boxes have no persisted value for their content hash
      alias_method :calculate_content_hash, :content_hash

      def calculate_content_hash!
        _content_hash { |el| el.calculate_content_hash! }
      end

      def _content_hash(&calculation)
        return "" if fields.empty? && empty?
        fields = fields_with_consistent_order.map(&calculation)
        entry_hashes = map(&calculation)
        Spontaneous::Model::Core::ContentHash.calculate(fields, entry_hashes)
      end
    end

    module FieldMethods
      def content_hash
        Spontaneous::Model::Core::ContentHash.calculate(unprocessed_value)
      end

      alias_method :calculate_content_hash,  :content_hash
      alias_method :calculate_content_hash!, :content_hash
    end

    module PagePieceMethods
      # Because pages all publish independently we don't want the content hash
      # of boxes to change if a contained page is modified, so make the hash
      # of pages inside boxes only depend on the id (so the box hash does change
      # when the page is added, moved or deleted)
      def content_hash
        return nil if target.never_published?
        Spontaneous::Model::Core::ContentHash.calculate(id)
      end
      alias_method :calculate_content_hash,  :content_hash
      alias_method :calculate_content_hash!, :content_hash
    end
  end
end
