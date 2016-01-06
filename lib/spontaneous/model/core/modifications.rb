module Spontaneous::Model::Core
  # Modifications is responsible for tracking changes made to Content items
  module Modifications
    extend Spontaneous::Concern

    class SlugModification
      def self.type
        :slug
      end

      attr_reader :owner, :user, :created_at, :old_value, :new_value

      def initialize(owner, user, created_at, old_value, new_value)
        @owner, @user, @created_at, @old_value, @new_value = owner, user, created_at, old_value, new_value
        @created_at = Time.parse(created_at) if @created_at.is_a?(String)
        @user = Spontaneous::Permissions::User[user] if @user.is_a?(Fixnum)
      end

      # Must apply this change the slow way by cascading updates from the parent because
      # otherwise it's difficult to publish changes to a child page's slug and publish them
      # separately
      def apply(revision)
        owner.with_revision(revision) do
          owner.force_path_changes_with_history(old_value, new_value)
        end
      end

      def dataset
        path_like = Sequel.like(:ancestor_path, "#{owner[:ancestor_path]}.#{owner.id}%")
        owner.content_model.filter(path_like)
      end

      def prepared_statement
        path_like = Sequel.like(:ancestor_path, :$path)
        owner.content_model.mapper.prepare(:count, :like_ancestor_path) {
          owner.content_model.select(Sequel::Dataset::COUNT_OF_ALL_AS_COUNT).filter(path_like)
        }
      end

      def count
        result = prepared_statement.call(path: search_path)
        result.first[:count]
      end

      def search_path
        "#{owner[:ancestor_path]}.#{owner.id}%"
      end

      def serialize
        [type, user_id, created_at.to_s(:rfc822), old_value, new_value]
      end

      def user_id
        @user.nil? ? nil : @user.id
      end

      def type
        self.class.type
      end

      def ==(other)
        super || (other.class == self.class &&
                  other.owner.id == self.owner.id &&
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

    class HiddenModification < SlugModification
      def self.type
        :visibility
      end

      def apply(revision)
        owner.with_revision(revision) do
          published = owner.content_model.get(owner.id)
          published.send(:set_visible_with_cascade!, !new_value)
        end
      end

      def prepared_statement
        path_like = Sequel.like(:visibility_path, :$path)
        owner.content_model::Page.mapper.prepare(:count, :like_visibility_path) {
          owner.content_model::Page.select(Sequel::Dataset::COUNT_OF_ALL_AS_COUNT).filter(path_like)
        }
      end

      def search_path
        "#{owner[:visibility_path]}.#{owner.id}%"
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

    class OwnerModification < SlugModification
      def self.type
        :owner
      end

      def initialize(owner, user, created_at, old_visibility_path, new_owner_id, new_box_sid)
        super(owner, user, created_at, old_visibility_path, new_owner_id)
        @new_box_sid = new_box_sid
      end

      def new_owner_id
        @new_value
      end

      def apply(revision)
        owner.with_revision(revision) do
          new_owner = owner.content_model.get(new_owner_id)
          published = owner.content_model.get(owner.id)
          published.contents.each do |content|
            content.set_visibility_path_from!(published)
          end
          published.save
        end
      end

      def prepared_statement
        path_like = Sequel.like(:visibility_path, :$path)
        owner.content_model::Page.mapper.prepare(:count, :like_visibility_path) {
          owner.content_model::Page.select(Sequel::Dataset::COUNT_OF_ALL_AS_COUNT).filter(path_like)
        }
      end

      def search_path
        "#{owner[:visibility_path]}.#{owner.id}%"
      end

      def serialize
        super << @new_box_sid
      end
    end

    def current_editor
      @current_editor
    end

    def current_editor=(user)
      @current_editor = user
    end

    def reload
      @local_modifications = nil
      super
    end

    def before_save
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
      with_editable { clear_pending_modifications! }
      with_revision(revision) { clear_pending_modifications! }
      super
    end

    def generate_modification_list
      serialize_pending_modifications if [create_slug_modifications, create_visibility_modifications, create_ownership_modifications].any? { |result| result }
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
        count = content_model::Page.count
        append_modification DeletionModification.new(self, current_editor, Time.now, count + @child_page_deletion_count, count)
      end
    end

    def create_visibility_modifications
      # We only want to record visibility changes that originate from user action, not ones propagated
      # from higher up the tree, hence the check against the hidden_origin.
      return false unless changed_columns.include?(:hidden) && hidden_origin.nil?
      if (previous_modification = local_modifications.detect { |mod| mod.type == :visibility })
        if previous_modification.old_value == hidden?
          remove_modification(:visibility)
        end
      else
        append_modification HiddenModification.new(self, current_editor, Time.now, !hidden?, hidden)
      end
      true
    end

    def create_slug_modifications
      change = changes_to_cascade[:slug]
      return false if change.nil?
      old_slug, new_slug = change.old_value, self[:slug]
      return false if old_slug.nil? # ignore first change of slug from nil to provided or generated
      if (previous_modification = local_modifications.detect { |mod| mod.type == :slug })
        if previous_modification.old_value == new_slug
          remove_modification(:slug)
        else
          previous_modification.new_value = new_slug
        end
      else
        append_modification SlugModification.new(self, current_editor, Time.now, old_slug, new_slug)
      end
      true
    end

    def create_ownership_modifications
      change = changes_to_cascade[:visibility_path]
      return false if change.nil?
      old_value, new_value = change.old_value, change.new_value
      return false if old_value.nil?
      return false if old_value == new_value
      if (previous_modification = local_modifications.detect { |mod| mod.type == :owner })
        if previous_modification.old_value == change.new_visibility_path
          remove_modification(:owner)
        else
          previous_modification.new_value = new_value
        end
      else
        append_modification OwnerModification.new(self, current_editor, Time.now, change.old_visibility_path, new_value, self[:box_sid])
      end
      true
    end

    def remove_modification(type)
      local_modifications.delete_if { |mod| mod.type == type }
    end

    def append_modification(modification)
      local_modifications.push modification
    end

    def pending_modifications(filter_type = nil)
      mods = all_pending_modifications
      return mods if filter_type.nil?
      mods.select { |mod| mod.type == filter_type }
    end

    def all_pending_modifications
      (local_modifications + pieces.flat_map { |piece| piece.local_modifications })
    end

    def clear_pending_modifications!
      self.serialized_modifications = nil
      self.class.filter(id: self.id).update(serialized_modifications: "[]")
      @local_modifications = nil
      pieces.each do |piece|
        piece.clear_pending_modifications!
      end
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
      Hash[[
        SlugModification,
        HiddenModification,
        DeletionModification,
        OwnerModification
      ].map { |mod_class| [mod_class.type, mod_class] }]
    end
  end
end
