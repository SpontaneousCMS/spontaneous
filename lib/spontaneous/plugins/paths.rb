
module Spontaneous::Plugins
  module Paths

    module ClassMethods
      def root
        Spontaneous::Page.first(:path => Spontaneous::SLASH)
      end
    end

    module InstanceMethods
      def after_initialize
        super
        self.slug = default_slug if slug.nil?
      end

      def before_create
        place_in_page_tree
        super
      end

      def after_save
        super
        check_for_path_changes
      end

      def default_slug
        "page-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
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
      end

      def root?
        path == Spontaneous::SLASH
      end

      def root
        Spontaneous::Page.root
      end

      def update_path
        self.path = calculate_path
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
          @__slug_changed = true
          self[:slug] = new_slug
          self.update_path
        end
      end

      def check_for_path_changes
        if @__slug_changed
          @__slug_changed = false
          children.each do |child|
            child.propagate_path_changes
          end
        end
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
end
