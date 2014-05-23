# encoding: UTF-8

module Spontaneous::Model::Page
  module Paths
    extend Spontaneous::Concern

    module ClassMethods
      def generate_default_slug
        "page-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
      end

      def is_default_slug?(slug)
        /^page-\d{8}-\d{6}$/ === slug
      end

      def create_root(slug)
        create(slug: slug, :__create_hidden_root =>  true)
      end
    end

    # InstanceMethods

    ANCESTOR_SEP = "."

    def __create_hidden_root=(state)
      @__is_hidden_root = state
    end

    def __create_hidden_root?
      @__is_hidden_root || false
    end

    private :__create_hidden_root=, :__create_hidden_root?

    def after_initialize
      super
      set_generated_slug
    end

    def before_create
      place_in_page_tree
      super
    end

    def after_insertion
      super
      fix_generated_slug_conflicts
    end

    def set_generated_slug
      return unless slug.nil?
      self.slug = generate_default_slug
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
      unless new?
        if (title = self.fields[title_field])
          set_slug_from_title(title)
        end
      end
      fix_generated_slug_conflicts
      super
    end

    # Syncing the slug with the title is made more difficult because the field
    # update mechanism works differently from the more direct, console version.
    # This is called by the field updater before re-serializing each modified field.
    def before_save_field(field)
      set_slug_from_title(field) if (field.name == title_field)
      super
    end

    def set_slug_from_title(title)
      if title.modified? and !title.blank? and has_generated_slug?
        self.slug = title.value
      end
    end

    def sync_slug_to_title
      self.slug = title.unprocessed_value
    end

    def has_generated_slug?
      self.class.is_default_slug?(slug)
    end

    def after_save
      super
      check_for_path_changes
    end

    def generate_default_slug
      self.class.generate_default_slug
    end

    def is_conflicting_slug?(slug)
      siblings.reject { |s| s.root? }.compact.map(&:slug).include?(slug)
    end

    def parent=(parent)
      @__parent_changed = true
      update_path
      super
    end

    def place_in_page_tree
      if parent_id.nil?
        if __create_hidden_root? || content_model.has_root?
          make_hidden_root
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

    def make_hidden_root
      raise Spontaneous::AnonymousRootException.new if slug.blank?
      self[:path] = "##{slug}"
      self[:ancestor_path] = ""
    end

    def ancestor_path
      (self[:ancestor_path] || "").split(ANCESTOR_SEP).map { |id| id.to_i }
    end

    def root?
      path == Spontaneous::SLASH
    end

    alias_method :is_root?, :root?


    def update_path
      self.path = calculate_path
      if parent
        self[:ancestor_path] = parent.ancestor_path.push(parent.id).join(ANCESTOR_SEP)
      end
    end


    def calculate_path
      calculate_path_with_slug(self.slug)
    end

    def calculate_path_with_slug(slug)
      if parent.nil?
        root? ? Spontaneous::SLASH : "##{slug}"
      else
        File.join(parent.path, slug)
      end
    end

    # slugs can be max 64 characters long
    def slug=(s)
      if (new_slug = fit_slug_to_length(s, 64)) != slug
        @__slug_changed = slug
        self[:slug] = new_slug
        self.update_path
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

    def check_for_path_changes(force = false)
      if @__slug_changed || force
        @__slug_changed = false
        children.each do |child|
          child.propagate_path_changes
        end
        aliases.each do |link|
          link.propagate_path_changes if link.page?
        end
      end
    end

    def force_path_changes
      check_for_path_changes(true)
    end

    def propagate_path_changes
      self.update_path
      self.save
      children.each do |child|
        child.propagate_path_changes
      end
    end
  end
end
