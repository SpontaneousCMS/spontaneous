# encoding: UTF-8

module Spontaneous::Plugins
  module Paths
    extend ActiveSupport::Concern

    module ClassMethods
      def generate_default_slug
        "page-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
      end

      def is_default_slug?(slug)
        /^page-\d{8}-\d{6}$/ === slug
      end
    end

    # InstanceMethods

    ANCESTOR_SEP = "."

    def after_initialize
      super
      self.slug = default_slug if slug.nil?
    end

    def before_create
      place_in_page_tree
      super
    end

    def before_save
      unless new?
        if title = self.fields[:title]
          if title.modified? and !title.blank? and self.class.is_default_slug?(slug)
            self.slug = title.value
          end
        end
      end
      super
    end

    def after_save
      super
      check_for_path_changes
    end

    def default_slug
      self.class.generate_default_slug
    end

    def parent=(parent)
      @__parent_changed = true
      update_path
      super
    end

    def place_in_page_tree
      if self.parent_id.nil?
        if Spontaneous::Page.root.nil?
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

    def ancestor_path
      (self[:ancestor_path] || "").split(ANCESTOR_SEP).map { |id| id.to_i }
    end

    def root?
      path == Spontaneous::SLASH
    end
    alias_method :is_root?, :root?

    def root
      Spontaneous::Page.root
    end

    def update_path
      self.path = calculate_path
      if parent
        self[:ancestor_path] = parent.ancestor_path.push(parent.id).join(ANCESTOR_SEP)
      end
    end


    def calculate_path
      if parent.nil?
        root? ? Spontaneous::SLASH : '' # bad case, no parent but not root
      else
        File.join(parent.path, slug)
      end
    end

    def slug=(s)
      if (new_slug = s.to_url) != self.slug
        @__slug_changed = self.slug
        # slugs can be max 255 characters long
        self[:slug] = new_slug[0..254]
        self.update_path
      end
    end

    def check_for_path_changes
      if @__slug_changed
        @__slug_changed = false
        children.each do |child|
          child.propagate_path_changes
        end
        aliases.each do |link|
          link.propagate_path_changes if link.page?
        end
      end
    end

    def propagate_path_changes
      # this happens in the child pages who shouldn't update their modification dates
      # because updates to paths are handled by modifications held on the origin of the path change
      @__ignore_page_modification = true
      self.update_path
      self.save
      children.each do |child|
        child.propagate_path_changes
      end
    end
  end
end
