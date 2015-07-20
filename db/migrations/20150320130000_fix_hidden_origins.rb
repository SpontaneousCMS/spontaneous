# encoding: UTF-8

Sequel.migration do
  # New aliases weren't inheriting their visibility from their target properly.
  # This migration fixes the mess left by that bug by correctly setting both the
  # visibility and the visibility_origin for aliases of hidden targets and
  # clearing the visibility origin for visible aliases of visible targets.
  up do
    # Don't run unless we're in a full Spontaneous instance i.e. not in a
    # testing environment
    if defined?(Content)
      aliases = Content.exclude(target_id: nil)
      aliases.each do |a|
        target = a.target
        if target.hidden?
          a.send :apply_set_visible!, false, target.id
          a.save
        else
          # The bug set the hidden origin to the id of the parent, not the target
          # so we want to clear that unless the alias was actually hidden directly
          # i.e. has a hidden_origin == nil
          unless a.hidden_origin.nil?
            a.send :apply_set_visible!, true, nil
            a.save
          end
        end
      end
    end
  end

  down do
    # no-op
  end
end
