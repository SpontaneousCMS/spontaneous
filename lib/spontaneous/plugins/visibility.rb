# encoding: UTF-8

module Spontaneous::Plugins
  module Visibility
    extend ActiveSupport::Concern

    module ClassMethods
      @@visible_filter = false

      def _set_visible_dataset!
        @_saved_dataset ||= self.dataset
        ds = filter_visible self.dataset
        @dataset = ds
        # set_dataset clears the row_proc which desroys the STI
        # self.set_dataset(ds)
      end

      def _restore_dataset!
        # self.set_dataset( self.dataset.unfiltered) if @_saved_dataset
        @dataset = @_saved_dataset if @_saved_dataset
        @_saved_dataset = nil
      end

      def _content_classes
        [Spontaneous::Content, Spontaneous::Page, Spontaneous::Piece] + Spontaneous.schema.content_classes
      end

      def _unfiltered_dataset
        @_saved_dataset or dataset
      end

      def with_visible(&block)
        if @@visible_filter
          yield
        else
          begin
            Spontaneous::Content._set_visible_dataset!
            @@visible_filter = true
            yield
          ensure
            @@visible_filter = false
            Spontaneous::Content._restore_dataset!
          end
        end
      end

      def visible_only?
        @@visible_filter
      end

      def visible
        filter_visible self.dataset
      end

      def filter_visible(dataset)
        dataset.filter(:hidden => false)
      end
    end # ClassMethods

    # InstanceMethods

    def visible?
      !self.hidden
    end

    def hidden?
      self.hidden
    end

    def hide!
      set_visible!(false)
    end

    def show!
      set_visible!(true)
    end

    def toggle_visibility!
      if hidden?
        show!
      else
        hide!
      end
    end

    ##
    # Is true when the current object is hidden independently of its ancestors
    # and false when hidden because one of its ancestors is hidden (so to show
    # this you need to show that ancestor)
    def showable?
      hidden? && hidden_origin.blank?
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

    def set_visible(visible, hidden_origin = nil)
      protect_root_visibility!
      if self.visible? != visible
        raise Spontaneous::NotShowable.new(self, hidden_origin) if hidden? && visible && !showable?
        self[:hidden] = !visible
        self[:hidden_origin] = hidden_origin
        @_visibility_modified = true
      end
    end

    def after_save
      super
      if @_visibility_modified
        hide_descendents(self.visible?)
        hide_aliases(self.visible?)
        @_visibility_modified = false
      end
    end

    def hide_aliases(visible)
      dataset = Spontaneous::Content.filter(:target_id => self.id)
      origin = visible ? nil : self.id
      dataset.update(:hidden => !visible, :hidden_origin => origin)
    end

    def hide_descendents(visible)
      path_like = :visibility_path.like("#{self[:visibility_path]}.#{self.id}%")
      origin = visible ? nil : self.id
      dataset = Spontaneous::Content.filter(path_like).filter(:hidden => visible)
      # if a child item has been made invisible *before* its parent then it exists
      # with hidden = true and hidden_origin = nil
      if visible
        dataset = dataset.filter(:hidden_origin => self.id)
      end
      dataset.update(:hidden => !visible, :hidden_origin => origin)

      dataset.each do |content|
        content.aliases.update(:hidden => !visible, :hidden_origin => origin)
      end

      ## I'm saving these for posterity: I worked out some Sequel magic and I don't want to lose it
      #
      # Spontaneous::Content.from(:content___p).filter(path_like).update(:visible => visible, :hidden_origin => origin)
      # Spontaneous::Content.filter(:page_id => self.id).set(:visible => visible, :hidden_origin => origin)
      ## Update with join:
      # Spontaneous::Content.from(:content___n, :content___p).filter(path_like).filter(:n__page_id => :p__id).set(:n__visible => visible, :n__hidden_origin => origin)
    end

    def protect_root_visibility!
      if self.is_page? && self.is_root?
        raise "Root page is not hidable"
      end
    end
  end
end
