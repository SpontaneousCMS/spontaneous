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

    def visibility_ancestors
      visibility_ancestor_ids.map { |id| content_model[id] }
    end

    def visibility_ancestor_ids
      return [] if visibility_path.blank?
      visibility_path.split(Spontaneous::VISIBILITY_PATH_SEP).map(&:to_i)
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
      set_visible(visible)
    end

    protected

    def set_visible(visible, origin = nil)
      return [] unless visible? != visible
      apply_set_visible(visible, origin)
      schedule_visibility_cascade(visible, origin || id)
    end

    def set_visible!(state)
      set_visible_with_cascade!(state)
    end

    def after_save
      super
      if (args = @_visibility_requires_cascade)
        @_visibility_requires_cascade = nil
        cascade_visibility(*args)
      end
    end

    def schedule_visibility_cascade(visible, origin)
      @_visibility_requires_cascade = [visible, origin]
    end

    def verify_visibility_change!(show)
      protect_root_visibility!
      return if !show || visible?
      raise Spontaneous::NotShowable.new(self, hidden_origin) unless showable?
    end

    # Private: Used by visibility modifications to force a cascade of visibility
    # state during the publish process.
    def set_visible_with_cascade!(state)
      apply_set_visible(state, nil)
      save
      cascade_visibility(state, id)
    end

    def apply_set_visible(visible, origin)
      verify_visibility_change!(visible)
      apply_set_visible!(visible, origin)
    end

    def apply_set_visible!(visible, origin)
      self[:hidden] = !visible
      self[:hidden_origin] = origin
    end

    def cascade_visibility(visible, origin)
      affected = find_descendents(visible)
      descendents = affected[1..-1]
      origin = nil if visible
      content_model.where(id: descendents.map(&:id)).update(hidden: !visible, hidden_origin: origin)
      descendents.each { |d| d.apply_set_visible!(visible, origin) }
      affected
    end

    def descendents_path
      child = Sequel.expr(visibility_path: visibility_join(visibility_path, id))
      deep  = Sequel.like(:visibility_path, visibility_join(visibility_path, id, "%"))
      (child | deep)
    end

    def visibility_join(*args)
      args.join(Spontaneous::VISIBILITY_PATH_SEP)
    end

    # find descendents
    # then all the aliases of descendents
    # then loop back to repeat the process starting from the aliases
    def find_descendents(visible)
      affected = []
      descendents = [self].concat(visibility_descendents([self], visible))
      loop do
        affected.concat(descendents)
        aliases = content_aliases(descendents, visible)
        # no need to continue if the descendents tree has no aliases to it
        break if aliases.empty?
        affected.concat(aliases)
        descendents = visibility_descendents(aliases, visible)
      end
      affected
    end

    def content_aliases(targets, visible)
      dataset = filter_for_visibility(content_model.filter(target_id: targets.map(&:id)), visible)
      dataset.all
    end

    def visibility_descendents(aliases, visible)
      expr = aliases[1..-1].inject(aliases[0].descendents_path) { |q, a| q | a.descendents_path }
      dataset = filter_for_visibility(content_model.filter(expr), visible)
      dataset.all
    end

    def filter_for_visibility(ds, visible)
      ds = ds.exclude(hidden: !visible)
      # if a child item has been made invisible *before* its parent then it exists
      # with hidden = true and hidden_origin = nil
      ds = ds.filter(hidden_origin: id) if visible
      ds
    end

    def recalculated_hidden
      visibility_ancestors.any? { |ancestor| ancestor.hidden? }
    end

    def protect_root_visibility!
      raise "Root page is not hidable" if (is_page? && is_root?)
    end
  end
end
