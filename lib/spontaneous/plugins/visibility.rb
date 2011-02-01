# encoding: UTF-8


module Spontaneous::Plugins
  module Visibility

    def self.configure(base)
    end

    module ClassMethods
      def with_visible(&block)
        yield
      end
    end # ClassMethods

    module InstanceMethods
      def visible?
        self.assigned_visible && self.inherited_visible
      end

      def hidden?
        !visible?
      end

      def hide!
        set_visible!(false)
      end

      def show!
        set_visible!(true)
      end


      def visible=(visible)
        protect_root_visibility!
        set_visible(visible)
      end

      protected

      def after_save
        super
        if @_visibility_modified
          if page?
            hide_page_descendents(self.visible?)
          else
            hide_facet_descendents(self.visible?)
          end
          @_visibility_modified = false
        end
      end

      def set_visible(visible, inherited = false, recurse = true)
        protect_root_visibility!
        if inherited
          self.inherited_visible = visible
        else
          self.assigned_visible = visible
        end
        @_visibility_modified = recurse
      end

      def set_visible!(state, inherited=false, recurse=true)
        self.set_visible(state, inherited, recurse)
        self.save
        self
      end

      def hide_page_descendents(visible)
        path_like = :p__ancestor_path.like("#{self[:ancestor_path]}.#{self.id}%")
        # hide all ancestor paths
        Spontaneous::Content.from(:content___p).filter(path_like).update(:inherited_visible => visible)
        # hide current page contents
        Spontaneous::Content.filter(:page_id => self.id).set(:inherited_visible => visible)
        # hide all descendent page content
        Spontaneous::Content.from(:content___n, :content___p).filter(path_like).filter(:n__page_id => :p__id).set(:n__inherited_visible => visible)
      end

      def hide_facet_descendents(visible)
        pages, non_pages = find_first_child_page_recurse(self)
        pages.each     { |c| c.set_visible!(visible, true, true) }
        non_pages.each { |c| c.set_visible!(visible, true, false) }
      end

      ## collect all child content of this node but stop at pages
      def find_first_child_page_recurse(content, pages=[], non_pages=[])
        content.entries.each do |e|
          if e.page?
            pages << e
          else
            non_pages << e
            find_first_child_page_recurse(e, pages, non_pages)
          end
        end
        [pages, non_pages]
      end

      def protect_root_visibility!
        if self.is_page? && self.is_root?
          raise "Root page is not hidable"
        end
      end
    end # InstanceMethods

  end
end



