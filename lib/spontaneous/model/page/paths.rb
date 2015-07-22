# encoding: UTF-8

module Spontaneous::Model::Page
  module Paths
    extend Spontaneous::Concern

    module ClassMethods
      def generate_default_slug(root = 'page')
        "#{root}-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
      end

      def is_default_slug?(slug, root = 'page')
        /^#{root}-\d{8}-\d{6}$/ === slug
      end

      def create_root(slug, values = {})
        create(values.merge(slug: slug, :__create_private_root =>  true))
      end
    end

    # InstanceMethods

    def __create_private_root=(state)
      @__is_private_root = state
    end

    def __create_private_root?
      @__is_private_root || false
    end

    private :__create_private_root=, :__create_private_root?

    def before_create
      place_in_page_tree
      set_slug_from_dynamic_value
      super
    end

    def after_insertion
      super
      fix_generated_slug_conflicts
    end

    def fix_generated_slug_conflicts
      o = s = slug || generate_default_slug
      n = 0
      while is_conflicting_slug?(s)
        n += 1
        s = "#{o}-#{n.to_s.rjust(2, "0")}"
      end
      self.slug = s
    end

    # Test for title changes and update the slug to match if it hasn't already
    # been set.
    #
    # This doesn't happen when the item is created (i.e. #new? => true)
    # because otherwise the slug would always take on the title fields
    # default value.
    def before_save
      if !new? && (title = fields[title_field_name])
        set_slug_from_title(title)
      end
      fix_generated_slug_conflicts
      super
    end

    def set_slug_from_dynamic_value
      if (title = fields[title_field_name]) && title.prototype.dynamic_default?
        set_slug_from_title!(title)
      end
    end

    # Syncing the slug with the title is made more difficult because the field
    # update mechanism works differently from the more direct, console version.
    # This is called by the field updater before re-serializing each modified field.
    def before_save_field(field)
      set_slug_from_title(field) if (field.name == title_field_name)
      super
    end

    def set_slug_from_title(title)
      if title.modified? and !title.blank? and has_generated_slug?
        set_slug_from_title!(title)
      end
    end

    def set_slug_from_title!(title)
      self.slug = title.value
    end

    def sync_slug_to_title
      self.slug = title.unprocessed_value
    end

    def has_generated_slug?
      self.class.is_default_slug?(slug, default_slug_root)
    end

    def generate_default_slug
      self.class.generate_default_slug(default_slug_root)
    end

    def default_slug_root
      'page'
    end

    def is_conflicting_slug?(slug)
      siblings(true).reject { |s| s.root? }.compact.map(&:slug).include?(slug)
    end

    def parent=(parent)
      @__parent_changed = true
      update_path
      super
    end

    def place_in_page_tree
      if parent_id.nil?
        if __create_private_root? || content_model.has_root?
          make_private_root
        else
          make_root
        end
      else
        update_path
      end
    end

    def make_root
      self[:path] = "/"
      self[:slug] = ""
      self[:ancestor_path] = ""
    end

    def make_private_root
      raise Spontaneous::AnonymousRootException.new if slug.blank?
      self[:path] = "##{slug}"
      self[:ancestor_path] = ""
    end

    def ancestor_path
      self.class.split_materialised_path(self[:ancestor_path])
    end

    def ancestor_path_ids
      self[:ancestor_path]
    end

    def is_public_root?
      path == Spontaneous::SLASH
    end

    alias_method :root?,    :is_public_root?
    alias_method :is_root?, :is_public_root?

    # Returns the root of the tree this page belongs to, which in the case
    # of pages in an private tree will not be the same as the site's
    # root/home page
    def tree_root
      content_model::Page.get(visibility_path_ids.first)
    end

    def is_private_root?
      return false unless parent_id.nil?
      return false if root?
      path[0] == '#'
    end

    def in_private_tree?
      tree_root = self.tree_root
      return is_private_root? if tree_root.nil?
      tree_root.is_private_root?
    end

    # Loads the current calculated path of this page from the database.
    # Used by Box#path! (which is itself used by #calculate_path_with_slug below)
    # It's necessary to grab this from the db because there are too many cached
    # values between the box & the up-to-date value
    def path!
      model.dataset.select(:path).get_unfiltered_raw(id).try(:[], :path)
    end

    def update_path
      if (r = mapper.current_revision )
        update_path_with_history(r)
      else
        update_path_without_history
      end
    end

    def update_path_with_history(revision)
      old_path = path
      update_path_without_history
      save_path_history(old_path, path, revision)
    end

    def update_path_without_history
      self.path = calculate_path
      if parent
        self[:ancestor_path] = parent.ancestor_path.push(parent.id).join(Spontaneous::Model::ANCESTOR_SEP)
      end
    end

    def initialized_slug
      return slug unless slug.nil?
      self.slug = generate_default_slug
    end

    def calculate_path
      calculate_path_with_slug(initialized_slug)
    end

    def calculate_path_with_slug(slug)
      if parent.nil?
        root? ? Spontaneous::SLASH : "##{slug}"
      else
        File.join(container.path!, slug)
      end
    end

    class SlugChange
      attr_reader :old_value, :new_value
      def initialize(origin, old_value, new_value)
        @origin, @old_value, @new_value = origin, old_value, new_value
      end

      def propagate
        return if @old_value == @new_value
        @origin.force_path_changes
      end
    end

    included do
      cascading_change :slug do |origin, old_value, new_value|
        SlugChange.new(origin, old_value, new_value)
      end
    end

    # slugs can be max 64 characters long
    def slug=(s)
      if (new_slug = fit_slug_to_length(s, 64)) != slug
        super(new_slug)
        update_path
      end
    end

    def fit_slug_to_length(s, max_length)
      original = s.to_url
      parts    = original.split('-')
      url      = [parts.shift]
      while !parts.empty? && ((url + [parts[0]]).join('-').length <= max_length)
        url << parts.shift
      end
      url.join('-')[0...max_length]
    end

    protected :fit_slug_to_length

    def force_path_changes_with_history(old_slug, new_slug)
      old_path = calculate_path_with_slug(old_slug)
      save_path_history(old_path, path, mapper.current_revision)
      force_path_changes
    end

    def force_path_changes
      children.each do |child|
        child.propagate_path_changes
      end
      aliases.each do |link|
        link.propagate_path_changes if link.page?
      end
    end

    def propagate_path_changes
      update_path
      save
      children.each do |child|
        child.propagate_path_changes
      end
    end
  end
end
