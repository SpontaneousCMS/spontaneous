# encoding: UTF-8

module Spontaneous::Model::Core
  module Entries
    extend Spontaneous::Concern

    # because it's possible to build content out of order
    # some relations don't necessarily get created straight away
    def before_save
      if owner
        self.page = owner.page if page.nil?
        if page?
          self.depth = parent ? ((parent.depth || 0) + 1) : 0
        else
          self.depth = (owner.content_depth || 0) + 1
        end
      end
      super
    end

    def depth
      super || 0
    end

    def destroy(remove_owner_entry=true, origin = nil)
      is_origin = origin.nil?
      origin ||= owner
      recursive_destroy(origin)
      origin.child_page_deleted! if (origin && page?)
      owner = self.owner
      super()
      @box.content_destroyed(self) if (@box && remove_owner_entry)
      origin.after_child_destroy if is_origin && origin
    end

    def recursive_destroy(origin)
      boxes.destroy(origin)
    end

    def content_depth
      depth
    end

    def contents
      contents_of(boxes)
    end

    def content_ids
      boxes.flat_map { |box| box.ids }
    end

    def contents_of(set)
      set.flat_map { |entry| entry.contents }
    end

    def first
      contents.first
    end

    def last
      contents.last
    end

    # Called on the inserted content after it has been placed into a box
    def after_insertion
    end

    # Called on the owning item after new content has been inserted into one
    # of its boxes
    def save_after_insertion(inserted_content)
      save
    end

    # added is my private mechanism for tracking if a content item is new
    def before_create
      @added = true
      super
    end

    def added?
      @added
    end

    def update_position(position)
      entry.set_position(position)
      owner.save
    end

    def set_position(new_position)
      box.set_position(self, new_position)
    end

    def style_for_content(content, box = nil)
      box.style_for_content(content)
    end

    def available_styles(content)
      content.class.styles
    end

    def owner=(owner)
      super
      set_visibility_path
    end

    def set_visibility_path
      self[:visibility_path] = [owner.visibility_path, owner.id].compact.join(Spontaneous::VISIBILITY_PATH_SEP)
    end

    def set_visibility_path!
      set_visibility_path
      save
    end
  end # Entries
end # Spontaneous::Plugins
