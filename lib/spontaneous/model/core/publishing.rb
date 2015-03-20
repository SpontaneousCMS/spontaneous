# encoding: UTF-8


module Spontaneous::Model::Core
  module Publishing
    extend Spontaneous::Concern

    module ClassMethods

      def revision_table(revision=nil)
        mapper.revision_table(revision)
      end

      def revision_table?(table_name)
        mapper.revision_table?(table_name)
      end

      def revision_exists?(revision)
        Spontaneous::Publishing::Revision.exists?(self, revision)
        # database.tables.include?(revision_table(revision).to_sym)
      end

      # Returns a list of all tables in the database that represent a content
      # revision.
      def revision_tables
        Spontaneous::Publishing::Revision.tables(self)
        # database.tables.select { |t| revision_table?(t) }.sort
      end

      def revision
        mapper.current_revision
      end

      def with_revision(revision=nil, &block)
        mapper.revision(revision, &block)
      end

      def scope(revision = nil, visible = false, &block)
        mapper.scope(revision, visible, &block)
      end

      # A version of scope that forces the creation of a new scope
      # thus allow us to bypass the cache within a particular block
      def scope!(revision = nil, visible = false, &block)
        mapper.scope!(revision, visible, &block)
      end

      def with_editable(&block)
        mapper.editable(&block)
      end

      def with_editable!(&block)
        mapper.editable!(&block)
      end

      def with_published(site, &block)
        scope(site.published_revision, true, &block)
      end

      def with_published!(site, &block)
        scope!(site.published_revision, true, &block)
      end

      def database
        Spontaneous.database
      end

      ##
      # Publish a revision
      #
      # If content is a non-empty list of Content ids then this will only publish changes to those
      # rows (taking the rest of the content from the previous revision)
      # Pass in a block if you want to tie some bit of post processing to the success or failure
      # of the publish step (used in the site render stage for example)
      def publish(revision, content=nil, &block)
        Spontaneous::Publishing::Revision.patch(self, revision, content, &block)
      end

      def publish_all(revision, &block)
        publish(revision, nil, &block)
      end

      def cleanup_revisions(current_revision, keep_revisions)
        Spontaneous::Publishing::Revision.cleanup(self, current_revision, keep_revisions)
      end

      # def delete_revision_table(revision)
      #   return if revision.nil?
      #   database.drop_table?(revision_table(revision))
      # end

      def delete_revision(revision)
        Spontaneous::Publishing::Revision.delete(self, revision)
      end

      def delete_all_revisions!
        Spontaneous::Publishing::Revision.delete_all(self)
      end

      # def drop_table(table)
      #   database.drop_table?(table)
      # end

      def history_dataset(revision = nil)
        Spontaneous::Publishing::Revision.history_dataset(self, revision)
      end

      def archive_dataset(revision = nil)
        Spontaneous::Publishing::Revision.archive_dataset(self, revision)
      end
    end # ClassMethods

    # InstanceMethods

    def after_create
      super
      page.modified!(page?) if page
    end

    def after_update
      super
      page.modified!(page?) if page
    end

    def modified!(caller_is_page)
      unless caller_is_page
        model.where(id: self.id).update(modified_at: Sequel.datetime_class.now)
      end
    end

    def with_revision(revision, &block)
      self.class.with_revision(revision, &block)
    end

    def scope(revision, visible, &block)
      self.class.scope(revision, visible, &block)
    end

    def with_editable(&block)
      self.class.with_editable(&block)
    end

    def never_published?
      first_published_at.nil?
    end

    def before_publish(revision); end
    def after_publish(revision);  end

    def sync_to_revision(revision, origin=false)
      # 'publish' is a lock to make sure the duplication doesn't cross
      # page boundaries unless that's necessary (such as in the case
      # of a page addition)
      publish = origin || !page?
      first_publish = false

      with_revision(revision) do
        published_copy = content_model.get(id)
        if published_copy
          if publish
            pieces_to_delete = published_copy.content_ids - with_editable { content_ids }
            pieces_to_delete.each do |content_id|
              if c = content_model.get(content_id)
                c.destroy(false) rescue ::Sequel::NoExistingObject
              end
            end
          end
        else # missing content (so force a publish)
          content_model.insert({id: id, type_sid: attributes[:type_sid]})
          publish = true
          first_publish = true
        end

        if publish
          before_publish(revision)
          with_editable do
            pieces.each do |entry|
              entry.sync_to_revision(revision, false)
            end
          end

          if page?
            sync_children_to_revision(revision)
          end

          content_model.where(id: id).update(attributes)

          published_values = {}
          # ancestors can have un-published changes to their paths so we can't just directly publish the current path.
          # Instead we re-calculate our path using the published version of the ancestor's path & our (potentially) updated slug.
          if page?
            published = self.class.get(id)
            published_values[:path] = published.calculate_path_with_slug(attributes[:slug])
          end

          # need to calculate the correct visibility for published items. I can't just take this from the editable
          # content because up-tree visibility changes might not have been published. This kinda mess is why individual
          # page publishing is a pain.
          # However, this only applies if the item's visibility is dependent on some up-tree state. So
          # if hidden_origin is empty (which means we have a separately calculated visibility) we want
          # to take visibility from our own value.

          published_values[:hidden] = recalculated_hidden unless hidden_origin.blank?

          unless published_values.empty?
            content_model.where(id: id).update(published_values)
          end

          after_publish(revision)
        end
      end
    end

    def sync_children_to_revision(revision)
      published_children = with_revision(revision) { content_model.filter(parent_id: self.id) }
      published_children.each do |child_page|
        deleted = with_editable { content_model.select(:id).get(child_page.id).nil? }
        if deleted
          with_revision(revision) do
            child_page.destroy
          end
        end
      end
    end

    # Finds an entry in the parent page and duplicates it to the parent
    # of the newly published page. Positions are not exact as other child pages might not have
    # been published.
    # def insert_entry_for_new_page(revision)
    #   return if parent_id.nil?
    #   _id = self.id
    #   detect_entry = proc { |content_id| content_id == _id }

    #   parent_content_ids = with_editable {
    #     content_model[self.parent_id].content_ids
    #   }
    #   entry = parent_content_ids.find(&detect_entry)
    #   index = parent_content_ids.index(&detect_entry)
    #   published_parent = content_model.get(parent_id)

    #   # store = published_parent.entry_store || []

    #   # unless store.find(&detect_entry)
    #     # store.insert(index, entry).compact!
    #     # published_parent.entry_store = store
    #   # end

    #   published_parent.save
    # end
  end
end
