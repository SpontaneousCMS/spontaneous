module Spontaneous::Plugins
  # Modifications is responsible for tracking changes made to Content items
  module Modifications
    extend ActiveSupport::Concern

    class SlugModification
      def self.type
        :slug
      end

      attr_reader :page, :created_at, :old_value, :new_value

      def initialize(page, created_at, old_value, new_value)
        @page, @created_at, @old_value, @new_value = page, created_at, old_value, new_value
        @created_at = Time.parse(created_at) if @created_at.is_a?(String)
      end

      # Must apply this change the slow way by cascading updates from the parent because
      # otherwise it's difficult to publish changes to a child page's slug and publish them
      # separately
      def apply(revision)
        page.with_revision(revision) do
          page.check_for_path_changes(true)
        end
      end

      def apply_modification(editable, published)
        published[:path] = editable[:path]
      end

      def dataset
        path_like = :ancestor_path.like("#{page[:ancestor_path]}.#{page.id}%")
        Spontaneous::Content.filter(path_like)
      end

      def count
        dataset.count
      end

      def serialize
        [created_at.to_s(:rfc822), old_value, new_value]
      end

      def type
        self.class.type
      end

      def ==(other)
        super || (other.class == self.class &&
                  other.page == self.page &&
                  other.old_value == self.old_value &&
                  other.new_value == self.new_value)
      end

      def inspect
        %(#<#{self.class}:#{self.object_id.to_s(16)} page="#{page.id}" old_value=#{old_value.inspect} new_value=#{new_value.inspect}>)
      end
    end

    class VisibilityModification < SlugModification
      def self.type
        :visibility
      end

      def apply(revision)
        self.page.with_editable do
          dataset.each do |editable|
            page.with_revision(revision) do
              published = S::Content.first :id => editable.id
              if published
                apply_modification(editable, published)
                published.save
              end
            end
          end
        end
      end

      def apply_modification(editable, published)
        published[:hidden] = editable[:hidden]
      end
    end

    class DeletionModification < SlugModification
      def self.type
        :deletion
      end

      def apply(revision)
        # Deletion modifications are handled higher up the publish chain.
        # The modification objects are merely for informational purposes.
      end

      def count
        old_value - new_value
      end
    end

    def reload
      @_modification_origin = @pending_modifications = nil
      super
    end

    def before_save
      # Home of many hacks.
      #
      # @__ignore_page_modification is set if a box has been modified by the addition of a page.
      # This is to correctly map changes to a list of pages to publish. In the case of a page
      # addition the change is owned by the new page.
      self.modified_at = Time.now unless @__ignore_page_modification or changed_columns.empty?
      # marks this object as the modified object appending modifications to the list
      # needed in order to know if changes to the modification list will be saved automatically
      # or if we need an explicit call to #save
      @_modification_origin = self
      generate_modification_list
      super
    end

    def after_publish(revision)
      modifications = pending_modifications.dup
      with_editable do
        self.pending_modifications.clear
        self.serialized_modifications = nil
        self.save
      end
      modifications.each do |type, modification|
        modification.apply(revision)
      end
      super
    end

    def generate_modification_list
      # return if modification_target.nil?
      modifications = [create_slug_modifications, create_visibility_modifications, create_deletion_modifications].compact
      serialize_pending_modifications
    end

    def child_page_deleted!
      @child_page_deletion_count ||= 0
      @child_page_deletion_count += 1
    end

    def after_child_destroy
      create_deletion_modifications && serialize_pending_modifications
      save
    end

    def create_deletion_modifications
      if @child_page_deletion_count && @child_page_deletion_count > 0
        count = S::Page.count
        DeletionModification.new(modification_target, Time.now, count + @child_page_deletion_count, count).tap do |modification|
          modification_target.append_modification(modification)
        end
      end
    end

    def create_visibility_modifications
      if changed_columns.include?(:hidden)
        if (previous_modification = modification_target.pending_modifications[:visibility])
          if previous_modification.old_value == hidden?
            modification_target.remove_modification(:visibility)
            return nil
          end
        end
        VisibilityModification.new(modification_target, Time.now, !hidden?, hidden).tap do |modification|
          modification_target.append_modification(modification)
        end
      end
    end

    def create_slug_modifications
      return unless (old_slug = @__slug_changed)
      if (previous_modification = modification_target.pending_modifications[:slug])
        if previous_modification.old_value == self[:slug]
          modification_target.remove_modification(:slug)
          return nil
        end
        old_slug = previous_modification.old_value
      end
      SlugModification.new(modification_target, Time.now, old_slug, self[:slug]).tap do |modification|
        modification_target.append_modification(modification)
      end
    end

    def modification_target
      self.page
    end

    def remove_modification(type)
      pending_modifications.delete(type)
      save unless @_modification_origin
    end

    def append_modification(modification)
      pending_modifications[modification.type] = modification
      save unless @_modification_origin
    end

    def pending_modifications
      @pending_modifications ||= deserialize_pending_modifications
    end

    def serialize_pending_modifications
      self.serialized_modifications = pending_modifications.map { |key, modification| [key, modification.serialize] }
    end

    def deserialize_pending_modifications
      values = Hash[self.serialized_modifications || []].symbolize_keys
      mods = {}
      class_map = modification_class_map
      values.map do |type, values|
        args = [self, *values]
        mods[type] = class_map[type].new(*args)
      end
      mods
    end

    def modification_class_map
      Hash[[SlugModification, VisibilityModification, DeletionModification].map { |mod_class| [mod_class.type, mod_class] }]
    end
  end
end
