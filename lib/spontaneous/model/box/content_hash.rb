# encoding: UTF-8

module Spontaneous::Model::Box
  module ContentHash
    def generated?
      _prototype.generated?
    end

    def content_hash
      _content_hash { |el| el.content_hash }
    end

    # boxes have no persisted value for its content hash
    alias_method :calculate_content_hash, :content_hash

    def calculate_content_hash!
      _content_hash { |el| el.calculate_content_hash! }
    end

    def _content_hash(&calculation)
      return "" if fields.empty? && empty?
      fields = fields_with_consistent_order.map(&calculation)
      entry_hashes = map(&calculation)
      Spontaneous::Model.content_hash(fields, entry_hashes)
    end
  end
end
