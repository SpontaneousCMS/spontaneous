# encoding: UTF-8

require 'forwardable'

module Spontaneous
  module Collections
    # Provides an Array-like list of the contents of a box.
    #
    # This is coordinated from each box instance, which is responsible for
    # caching instances of these on a per-scope basis.
    #
    # The contents of the underlying array are loaded from the database on
    # initialization and any modifications to the contents of the array are
    # passed onto the underlying db table.
    class BoxContents < ::Array

      attr_reader :box, :schema_id

      def initialize(box)
        super()
        @box, @schema_id = box, box.schema_id
        load_contents
      end

      def ids
        map(&:id)
      end

      alias_method :insert_array, :insert

      # Over-rides the Array#insert method in order to write any changes to
      # the db. The special casing of the position is to allow for
      # optimizations/simplifications to the DB insertion methodology
      # depending on where the new item is being inserted
      def insert(index, content)
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

      def load_contents
        replace(load_contents!)
      end

      def load_contents!
        @count = 0
        box.load_contents.map { |content|
          content.to_entry(box, (@count += 1) - 1)
        }
      end

      def readonly?
        box.model.visible_only?
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

      def wrap_page(content)
        find { |e| e.id == content.id }
      end

      def to_ary
        dup
      end

      def to_a
        dup
      end

      def content_destroyed(content)
        remove_content(content)
        guarantee_box_ordering
      end

      private

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
        insert_array(position, entry)
        @count += 1
        content.save
        guarantee_box_ordering
        content
      end

      # update content
      # set box_position = ordering.row_number
      # from (
      #   select
      #     id,
      #     (row_number()  over(order by box_position) - 1) as row_number
      #   from content
      #   where
      #     ("owner_id" = 4115) AND ("box_sid" = 'boza1m6i002')
      #   ) ordering
      # where
      #   ordering.id = content.id;
      #
      # Updates the ordering of box content so that it is always 0-n with no
      # duplicates
      def guarantee_box_ordering
        ds = box.unordered_dataset.ds
        # TODO: a version of this for dbs that don't support window functions...
        if ds.supports_window_functions?
          sub = ds.select { [:id, Sequel.as(row_number.function.over(order: Sequel.asc(:box_position)) - 1, :row_number)] }
          ds.unfiltered.from(:content, Sequel.as(sub, :ordering)).where(content__id: :ordering__id).update(box_position: :ordering__row_number)
        end
      end

      def content_attributes(content, position)
        { box_position: position,
          box_sid: schema_id,
          owner: owner,
          style: style_for_content(content),
          _prototype: prototype_for_content(content),
          depth: content.content_tree_depth(owner)
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
        return {} if page.nil?
        content.parent = page
        content.update_path
        {}
      end

      def piece_attributes(content)
        { page: page }
      end

      def remove_content(content)
        @count -= 1 unless @count.nil?
        box.unordered_dataset.where { box_position >= content.box_position }.update(box_position: (Sequel.expr(:box_position) - 1))
        delete_if { |c| c.id == content.id }
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
    end
  end
end