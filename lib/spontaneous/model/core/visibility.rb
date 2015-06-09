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


    # When we're placed into the content tree we want to inherit our
    # visibility from our new owner
    def owner=(owner)
      set_visible(owner.visible?, owner.id)
      super
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

    def set_visible(visible, origin = nil)
      protect_root_visibility!
      if self.visible? != visible
        raise Spontaneous::NotShowable.new(self, hidden_origin) if hidden? && visible && !showable?
        apply_set_visible(visible, origin)
      end
    end

    def visibility_ancestors
      visibility_ancestor_ids.map { |id| content_model[id] }
    end

    def visibility_ancestor_ids
      return [] if visibility_path.blank?
      visibility_path.split(Spontaneous::VISIBILITY_PATH_SEP).map(&:to_i)
    end

    protected

    # Private: Used by visibility modifications to force a cascade of visibility
    # state during the publish process.
    def set_visible_with_cascade!(state)
      set_visible(state)
      force_visibility_cascade(id)
      self.save
      self
    end

    def apply_set_visible(visible, origin)
      self[:hidden] = !visible
      self[:hidden_origin] = origin
      force_visibility_cascade(origin || id)
    end

    def force_visibility_cascade(origin)
      @_visibility_modified = origin
    end

    def after_save
      super
      if (origin = @_visibility_modified)
        propagate_visibility_state(origin)
        @_visibility_modified = false
      end
    end

    def propagate_visibility_state(origin)
      affected = []
      affected.concat hide_descendents(visible?, origin)
      affected.concat hide_aliases(visible?, origin)
    end

    def hide_aliases(visible, origin)
      dataset = content_model.filter(target_id: id)
      apply_visibility_to_dataset(dataset, visible, origin)
    end

    def hide_descendents(visible, origin)
      hidden = !visible
      path_like = Sequel.like(:visibility_path, "#{self[:visibility_path]}.#{self.id}%")
      dataset = content_model.filter(path_like).exclude(hidden: hidden)

      # if a child item has been made invisible *before* its parent then it exists
      # with hidden = true and hidden_origin = nil
      dataset = dataset.filter(hidden_origin: origin) if visible
      apply_visibility_to_dataset(dataset, visible, origin)
    end

    def apply_visibility_to_dataset(dataset, visible, origin)
      origin = nil if visible
      dataset.map do |content|
        content.apply_set_visible(visible, origin)
        content.save
        content
      end
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
