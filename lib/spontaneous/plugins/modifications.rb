module Spontaneous::Plugins
  # Modifications is responsible for tracking changes made to Content items
  module Modifications
    extend ActiveSupport::Concern

    class SlugModification
      def self.type
        :slug
      end

      attr_reader :owner, :created_at, :old_value, :new_value

      def initialize(owner, created_at, old_value, new_value)
        @owner, @created_at, @old_value, @new_value = owner, created_at, old_value, new_value
        @created_at = Time.parse(created_at) if @created_at.is_a?(String)
      end

      # Must apply this change the slow way by cascading updates from the parent because
      # otherwise it's difficult to publish changes to a child page's slug and publish them
      # separately
      def apply(revision)
        owner.with_revision(revision) do
          owner.force_path_changes
        end
      end

      def dataset
        path_like = :ancestor_path.like("#{owner[:ancestor_path]}.#{owner.id}%")
        Spontaneous::Content.filter(path_like)
      end

      def count
        dataset.count
      end

      def serialize
        [type, created_at.to_s(:rfc822), old_value, new_value]
      end

      def type
        self.class.type
      end

      def ==(other)
        super || (other.class == self.class &&
                  other.owner == self.owner &&
                  other.old_value == self.old_value &&
                  other.new_value == self.new_value)
      end

      def new_value=(value)
        @created_at = Time.now
        @new_value = value
      end

      def inspect
        %(#<#{self.class}:#{self.object_id.to_s(16)} owner="#{owner.id}" old_value=#{old_value.inspect} new_value=#{new_value.inspect}>)
      end
    end

    class VisibilityModification < SlugModification
      def self.type
        :visibility
      end

      def apply(revision)
        owner.with_revision(revision) do
          published = Spontaneous::Content.first :id => owner.id
          published.propagate_visibility_state
        end
      end

      def dataset
        path_like = :visibility_path.like("#{owner[:visibility_path]}.#{owner.id}%")
        Spontaneous::Page.filter(path_like)
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
      @local_modifications = nil
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
      generate_modification_list
      super
    end

    def after_publish(revision)
      pending_modifications.each do |modification|
        modification.apply(revision)
      end
      with_editable do
        self.clear_pending_modifications!
      end
      with_revision(revision) do
        self.clear_pending_modifications!
      end
      super
    end

    def generate_modification_list
      create_slug_modifications
      create_visibility_modifications
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
        append_modification DeletionModification.new(self, Time.now, count + @child_page_deletion_count, count)
      end
    end

    def create_visibility_modifications
      if changed_columns.include?(:hidden)
        if (previous_modification = local_modifications.detect { |mod| mod.type == :visibility })
          if previous_modification.old_value == hidden?
            remove_modification(:visibility)
            return nil
          end
        end
        append_modification VisibilityModification.new(self, Time.now, !hidden?, hidden)
      end
    end

    def create_slug_modifications
      return unless (old_slug = @__slug_changed)
      if (previous_modification = local_modifications.detect { |mod| mod.type == :slug })
        if previous_modification.old_value == self[:slug]
          remove_modification(:slug)
          return nil
        end
        previous_modification.new_value = self[:slug]
      else
        append_modification SlugModification.new(self, Time.now, old_slug, self[:slug])
      end
    end

    def remove_modification(type)
      local_modifications.delete_if { |mod| mod.type == type }
    end

    def append_modification(modification)
      local_modifications.push modification
    end

    def pending_modifications(filter_type = nil)
      (local_modifications + pieces.flat_map { |piece| piece.local_modifications })
    end

    def clear_pending_modifications!
      self.serialized_modifications = nil
      @local_modifications = nil
      pieces.each do |piece|
        piece.clear_pending_modifications!
        piece.save
      end
      self.save
    end

    def serialize_pending_modifications
      self.serialized_modifications = local_modifications.map { |modification| modification.serialize }
    end

    def local_modifications
      @local_modifications ||= deserialize_local_modifications
    end

    def deserialize_local_modifications
      values = self.serialized_modifications || []
      class_map = modification_class_map
      values.map do |(type, *values)|
        type = type.to_sym
        args = [self, *values]
        class_map[type].new(*args)
      end
    end

    def modification_class_map
      Hash[[SlugModification, VisibilityModification, DeletionModification].map { |mod_class| [mod_class.type, mod_class] }]
    end
  end
end
