# encoding: UTF-8

require 'forwardable'

module Spontaneous
  module Collections
    class BoxContents
      include Enumerable
      extend Forwardable

      def_delegators :store, :+, :[]

      attr_reader :box, :schema_id


      def initialize(box)
        @box = box
        @schema_id = box.schema_id
        reset
      end

      def ids
        store.map(&:id)
      end

      def insert(index, content)
        raise ReadOnlyScopeModificationError.new(box) if readonly?
        case index
        when 0
          insert_at_beginning(content)
        when -1
          insert_at_end(content)
        else
          insert_at_position(index, content)
        end
      end

      def set_position(content, position)
        remove_content(content)
        insert(position, content)
      end

      def index(content)
        store.index(content)
      end

      def store
        mapper.with_cache(scope_cache_key) { load_contents }
      end

      def readonly?
        box.model.visible_only?
      end

      def scope_cache_key
        @scope_cache_key ||= ['box', owner.id, box.schema_id.to_s].join(':').freeze
      end

      def load_contents
        @count = 0
        box.dataset.map { |content|
          content.to_entry(box, (@count += 1) - 1)
        }
      end

      def each
        return enum_for(:each) unless block_given?
        store.each(&Proc.new)
      end

      def length
        store.length
      end

      def empty?
        store.empty?
      end

      def last
        store.last
      end

      def sample(n = 1)
        store.sample(n)
      end

      # An implementation of the Array#sample method that doesn't load the
      # entire box contents. Unfortunately there's no cross-db 'random' method
      # so we have to make two calls to the db.
      def sample!
        return nil if count == 0
        return first if count == 1
        box.dataset.offset(rand(count)).first
      end

      def count
        @count ||= box.unordered_dataset.count
      end

      def clear!
        destroy
      end

      def destroy(origin = nil)
        store.each do |content|
          content.destroy(false, origin)
        end
        reset
      end

      def insert_at_beginning(content)
        box.unordered_dataset.update(box_position: (Sequel.expr(:box_position) + 1))
        claim_content(content, 0)
      end

      def insert_at_end(content)
        claim_content(content, box.unordered_dataset.count)
      end

      def insert_at_position(index, content)
        box.unordered_dataset.where { box_position >= index }.update(box_position: (Sequel.expr(:box_position) + 1))
        claim_content(content, index)
      end

      def claim_content(content, position)
        entry = content.to_entry(box, position)
        content.set(content_attributes(content, position))
        store.insert(position, entry)
        @count += 1
        content.save
        content
      end

      def wrap_page(content)
        find { |e| e.id == content.id }
      end

      def page_entry(content)
        Spontaneous::PagePiece.new(owner, content)
      end

      def content_attributes(content, position)
        { box_position: position,
          box_sid: schema_id,
          owner: owner,
          style: style_for_content(content),
          _prototype: prototype_for_content(content)
        }.merge(content_type_attributes(content))
      end

      def content_type_attributes(content)
        if content.page?
          page_attributes(content)
        else
          piece_attributes(content)
        end
      end

      def page_attributes(content)
        if page
          content.parent = page
          content.update_path
          return {
            depth: page.depth + 1,
            parent_id: page.id
          }
        end
        {}
      end

      def piece_attributes(content)
        { depth: box.owner.content_depth, page: page }
      end

      def content_destroyed(content)
        remove_content(content)
      end

      def remove_content(content)
        @count -= 1 unless @count.nil?
        box.unordered_dataset.where { box_position >= content.box_position }.update(box_position: (Sequel.expr(:box_position) - 1))
        store.delete_if { |c| c.id == content.id }
      end

      def owner
        box.owner
      end

      def page
        box.owner.page
      end

      def style_for_content(content)
        box.style_for_content(content)
      end

      def prototype_for_content(content)
        box.prototype_for_content(content)
      end

      def to_ary
        store.dup
      end

      def to_a
        store.dup
      end

      private

      def reset
        mapper.clear_cache(scope_cache_key)
        @count = nil
      end

      def mapper
        box.model.mapper
      end
    end
  end
end