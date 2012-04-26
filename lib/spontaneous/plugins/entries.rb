# encoding: UTF-8

module Spontaneous::Plugins
  module Entries
    extend ActiveSupport::Concern

    included do
      alias_method :<<, :push
    end
    #
    #     def self.configure(base)
    #       base.__send__(:alias_method,  :<<, :push)
    #     end

    # InstanceMethods


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

    def after_save
      contents.each do |entry|
        entry.save if entry.modified?
      end
      super
    end

    def destroy(remove_owner_entry=true, origin = nil)
      is_origin = origin.nil?
      origin ||= owner
      recursive_destroy(origin)
      origin.child_page_deleted! if (origin && page?)
      owner = self.owner
      owner.destroy_entry!(self) if (owner && remove_owner_entry)
      super()
      origin.after_child_destroy if is_origin && origin
    end

    def recursive_destroy(origin)
      all_contents.destroy(origin)
    end

    def destroy_entry!(entry)
      contents.remove(entry)
      # save the owner because it won't be obvious to the caller
      # that content other than the destroyed object will have been
      # modified
      self.save
    end

    def content_depth
      depth
    end

    def entry_modified!(modified_entry)
      @__ignore_page_modification = modified_entry && modified_entry.page?
      self.entry_store = all_contents.serialize_db
    end

    def contents
      return visible_contents if Spontaneous::Content.visible_only?
      all_contents
    end

    # ensure that all access to pieces is through their corresponding entry
    # alias_method :pieces, :entries

    def all_contents
      @all_contents ||= Spontaneous::Collections::EntrySet.new(self, entry_store)
    end

    def visible_contents
      @visible_contents ||= all_contents.visible!
    end

    protected(:all_contents, :visible_contents)

    def reload
      @all_contents = @visible_contents = nil
      super
    end


    def first
      contents.first
    end

    def last
      contents.last
    end

    def push(page_or_piece)
      insert(-1, page_or_piece)
    end

    def insert(index, page_or_piece, box)
      save if new?
      if page_or_piece.page?
        insert_page(index, page_or_piece, box)
      else
        insert_piece(index, page_or_piece, box)
      end
    end


    def insert_page(index, child_page, box)
      child_page.owner = self
      if page
        child_page.depth = page.depth + 1
        page.unordered_children << child_page
        child_page.parent = page
        child_page.update_path
      end
      insert_with_style(:page, index, child_page, box)
    end

    def insert_piece(index, piece, box)
      piece.owner = self
      piece.page = page if page
      piece.depth = (content_depth || 0) + 1
      insert_with_style(:piece, index, piece, box)
    end

    def insert_with_style(type, index, content, box)
      self._pieces << content
      entry_style = style_for_content(content, box)
      content.box_sid = box.schema_id if box
      content._prototype = box.prototype_for_content(content) if box
      content.set_visible(self.visible?, self.id)
      content.save if content.new?
      entry = \
        case type
      when :page
        Spontaneous::PagePiece.new(self, content, entry_style ? entry_style.schema_id : nil)
      when :piece
        content.style = entry_style
        content
      end
      begin
        contents.insert(index, box, entry)
      rescue TypeError, RuntimeError => e
        # TODO: raise a custom more helpful error here
        logger.error { "Attempting to modify visible only pieces" }
        raise e
      end

      entry
    end

    def update_position(position)
      entry.set_position(position)
      owner.save
    end

    def set_position(new_position)
      if box
        box.set_position(self, new_position)
      else
        owner.contents.set_position(self, new_position)
      end
    end

    def style_for_content(content, box = nil)
      if box
        box.style_for_content(content)
      else
        content.default_style
      end
    end

    def available_styles(content)
      content.class.styles
    end

    def owner=(owner)
      super
      self[:visibility_path] = [owner.visibility_path, owner.id].compact.join(Spontaneous::VISIBILITY_PATH_SEP)
    end
  end # Entries
end # Spontaneous::Plugins
