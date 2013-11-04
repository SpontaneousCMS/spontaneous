# encoding: UTF-8

module Spontaneous::Model::Core
  module Visibility
    extend Spontaneous::Concern

    module ClassMethods
      def with_visible(&block)
        mapper.visible do
          yield
        end
      end

      def visible_only?
        mapper.visible_only?
      end
    end # ClassMethods

    # InstanceMethods

    def visible?
      !self.hidden?
    end

    def hidden?
      self.hidden || false
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

    def set_visible!(state)
      self.set_visible(state)
      self.save
      self
    end

    # Private: Used by visibility modifications to force a cascade of visibility
    # state during the publish process.
    def set_visible_with_cascade!(state)
      set_visible(state)
      force_visibility_cascade
      self.save
      self
    end

    def set_visible(visible, hidden_origin = nil)
      protect_root_visibility!
      if self.visible? != visible
        raise Spontaneous::NotShowable.new(self, hidden_origin) if hidden? && visible && !showable?
        self[:hidden] = !visible
        self[:hidden_origin] = hidden_origin
        force_visibility_cascade
      end
    end

    def force_visibility_cascade
      @_visibility_modified = true
    end

    def after_save
      super
      if @_visibility_modified
        propagate_visibility_state
        @_visibility_modified = false
      end
    end

    def propagate_visibility_state
      hide_descendents(self.visible?)
      hide_aliases(self.visible?)
    end

    def hide_aliases(visible)
      dataset = content_model.filter(:target_id => self.id)
      origin = visible ? nil : self.id
      dataset.update(:hidden => !visible, :hidden_origin => origin)
    end

    def hide_descendents(visible)
      path_like = :visibility_path.like("#{self[:visibility_path]}.#{self.id}%")
      origin = visible ? nil : self.id
      dataset = content_model.filter(path_like).filter(:hidden => visible)
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

    def visibility_ancestors
      visibility_ancestor_ids.map { |id| content_model[id] }
    end

    def visibility_ancestor_ids
      return [] if visibility_path.blank?
      visibility_path.split(Spontaneous::VISIBILITY_PATH_SEP).map(&:to_i)
    end

    def recalculated_hidden
      visibility_ancestors.any? { |ancestor| ancestor.hidden? }
    end

    def protect_root_visibility!
      if self.is_page? && self.is_root?
        raise "Root page is not hidable"
      end
    end
  end
end
