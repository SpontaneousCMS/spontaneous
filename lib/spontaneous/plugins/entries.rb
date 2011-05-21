# encoding: UTF-8

module Spontaneous::Plugins
  module Entries

    def self.configure(base)
      base.__send__(:alias_method,  :<<, :push)
    end

    module InstanceMethods
      CONTENT_PATH_SEP = ".".freeze

      # because it's possible to build content out of order
      # some relations don't necessarily get created straight away
      def before_save
        if container
          self.page = container.page if page.nil?
          if page?
            self.depth = parent ? ((parent.depth || 0) + 1) : 0
          else
            self.depth = (container.content_depth || 0) + 1
          end
        end
        super
      end

      def after_save
        pieces.each do |entry|
          entry.save if entry.modified?
        end
        super
      end

      def destroy(remove_container_entry=true, container=nil)
        container ||= self.container
        if container && remove_container_entry
          container.destroy_entry!(self)
        end
        super()
      end

      def before_destroy
        recursive_destroy
        super
      end

      def recursive_destroy
        all_pieces.destroy
      end

      def destroy_entry!(entry)
        pieces.remove(entry)
        # save the container because it won't be obvious to the caller
        # that content other than the destroyed object will have been
        # modified
        self.save
      end

      def content_depth
        depth
      end

      def entry_modified!(modified_entry)
        self.entry_store = all_pieces.serialize
      end

      def pieces
        if Spontaneous::Content.visible_only?
          visible_pieces
        else
          all_pieces
        end
      end

      # ensure that all access to pieces is through their corresponding entry
      # alias_method :pieces, :entries

      def all_pieces
        @all_pieces ||= Spontaneous::EntrySet.new(self, entry_store)
      end

      def visible_pieces
        @visible_pieces ||= all_pieces.visible!
      end

      protected(:all_pieces, :visible_pieces)

      def reload
        @all_pieces = @visible_pieces = nil
        super
      end


      def first
        pieces.first
      end

      def last
        pieces.last
      end

      def push(page_or_piece)
        insert(-1, page_or_piece)
      end

      def insert(index, page_or_piece, box = nil)
        save if new?
        if page_or_piece.page?
          insert_page(index, page_or_piece, box)
        else
          insert_piece(index, page_or_piece, box)
        end
      end


      def insert_page(index, child_page, box = nil)
        child_page.container = self
        if page
          child_page.depth = page.depth + 1
          page.children << child_page
          child_page.parent = page
          child_page.update_path
        end
        insert_with_style(:page, index, child_page, box)
      end

      def insert_piece(index, piece, box = nil)
        piece.container = self
        piece.page = page if page
        piece.depth = (content_depth || 0) + 1
        insert_with_style(:piece, index, piece, box)
      end

      def insert_with_style(type, index, content, box = nil)
        self._pieces << content
        entry_style = style_for_content(content, box)
        content.box_id = box.box_id if box
        content._prototype = box.prototype_for_content(content) if box
        content.save if content.new?
        entry = \
          case type
          when :page
            Spontaneous::PagePiece.new(self, content, entry_style.style_id)
          when :piece
            content.style = entry_style
            content
          end
        begin
          pieces.insert(index, entry)
        rescue TypeError, RuntimeError => e
          # TODO: raise a custom more helpful error here
          logger.error { "Attempting to modify visible only pieces" }
          raise e
        end

        entry
      end

      def update_position(position)
        entry.set_position(position)
        container.save
      end

      def set_position(new_position)
        if box
          box.set_position(self, new_position)
        else
          container.pieces.set_position(self, new_position)
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

      def container=(container)
        super
        self[:content_path] = [container.content_path, container.id].compact.join(CONTENT_PATH_SEP)
      end

    end # InstanceMethods
  end # Entries
end # Spontaneous::Plugins

