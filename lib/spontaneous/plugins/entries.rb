module Spontaneous::Plugins
  module Entries

    def self.configure(base)
      base.send(:alias_method,  :<<, :push)
    end

    module InstanceMethods
      def entry_modified!(modified_entry)
        self.entries.update!
      end

      def entries
        @entries ||= Spontaneous::EntrySet.new(self, :entry_store)
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
        entry_style = style_for_content(child_page)
        entry = Spontaneous::Entry.page(self, child_page, entry_style)
        entries.insert(index, entry)
        entry
      end

      def insert_facet(index, facet)
        facet.container = self
        facet.page = page if page
        facet.depth = depth + 1
        entry_style = style_for_content(facet)
        entry = Spontaneous::Entry.facet(self, facet, entry_style)
        entries.insert(index, entry)
        entry
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
    end
  end
end

