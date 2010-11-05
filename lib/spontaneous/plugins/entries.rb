# encoding: UTF-8

module Spontaneous::Plugins
  module Entries

    def self.configure(base)
      base.send(:alias_method,  :<<, :push)
    end

    module InstanceMethods

      # because it's possible to build content out of order
      # some relations don't necessarily get created straight away
      def before_save
        if container 
          self.page = container.page if page.nil?
          self.depth = (container.content_depth || 0) + 1
        end
        super
      end

      def content_depth
        depth
      end

      def entry_modified!(modified_entry)
        self.entry_store = entries.serialize
      end

      def entries
        @entries ||= Spontaneous::EntrySet.new(self, entry_store)
      end

      def reload
        @entries = nil
        super
      end

      def visible_entries
        entries
      end


      def first
        entries.first
      end

      def last
        entries.last
      end

      def push(page_or_facet)
        insert(-1, page_or_facet)
      end

      def insert(index, page_or_facet)
        save if new?
        if page_or_facet.page?
          insert_page(index, page_or_facet)
        else
          insert_facet(index, page_or_facet)
        end
      end


      def insert_page(index, child_page)
        if page
          child_page.depth = page.depth + 1
          page.children << child_page
          child_page.parent = page
          child_page.update_path
        end
        insert_with_style(:page, index, child_page)
      end

      def insert_facet(index, facet)
        facet.container = self
        facet.page = page if page
        facet.depth = (depth || 0) + 1
        insert_with_style(:facet, index, facet)
      end

      def insert_with_style(type, index, content)
        entry_style = style_for_content(content)
        entry = Spontaneous::Entry.send(type, self, content, entry_style)
        entries.insert(index, entry)
        entry
      end

      def update_position(position)
        container.entries.set_position(self, position)
        container.save
      end

      def style_for_content(content)
        content.styles.default
      end

      def available_styles(content)
        content.styles
      end

      def entry=(entry)
        @entry = entry
      end

      def entry
        @entry ||= resolve_entry
      end

      def resolve_entry
        container.entries.find { |e| e.target_id == self.id }
      end

      def method_missing(method, *args, &block)
        if entry = entries.labelled(method)
          entry
        else
          super
        end
      end
    end # InstanceMethods
  end # Entries
end # Spontaneous::Plugins

