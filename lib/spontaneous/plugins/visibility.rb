# encoding: UTF-8


module Spontaneous::Plugins
  module Visibility
    S = Spontaneous unless defined?(S)

    def self.configure(base)
    end

    module ClassMethods
      @@visible_filter = false

      def with_visible(&block)
        begin
          @@visible_filter = true
          yield
        ensure
          @@visible_filter = false
        end
      end

      def visible_only?
        @@visible_filter
      end
    end # ClassMethods

    module InstanceMethods
      def visible?
        self.visible
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

      def set_visible!(state)
        self.set_visible(state)
        self.save
        self
      end

      def set_visible(visible)
        protect_root_visibility!
        if self.visible? != visible
          self[:visible] = visible
          self[:visibility_origin] = nil
          @_visibility_modified = true
        end
      end

      def after_save
        super
        if @_visibility_modified
          hide_descendents(self.visible?)
          @_visibility_modified = false
        end
      end

      def hide_descendents(visible)
        path_like = :content_path.like("#{self[:content_path]}.#{self.id}%")
        origin = visible ? nil : self.id
        Spontaneous::Content.filter(path_like).update(:visible => visible, :visibility_origin => origin)

        ## I'm saving these for posterity: I worked out some Sequel magic and I don't want to lose it
        #
        # Spontaneous::Content.from(:content___p).filter(path_like).update(:visible => visible, :visibility_origin => origin)
        # Spontaneous::Content.filter(:page_id => self.id).set(:visible => visible, :visibility_origin => origin)
        ## Update with join:
        # Spontaneous::Content.from(:content___n, :content___p).filter(path_like).filter(:n__page_id => :p__id).set(:n__visible => visible, :n__visibility_origin => origin)
      end

      def protect_root_visibility!
        if self.is_page? && self.is_root?
          raise "Root page is not hidable"
        end
      end
    end # InstanceMethods

  end
end



