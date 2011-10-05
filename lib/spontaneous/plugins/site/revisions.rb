# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Revisions
      module ClassMethods
        def working_revision
          Spontaneous::State.revision
        end

        def revision
          Spontaneous::State.revision
        end

        def published_revision
          Spontaneous::State.published_revision
        end

        def pending_revision
          Spontaneous::State.pending_revision
        end

        def revision_dir(revision=nil, root = nil)
          root ||= instance.revision_root
          instance.revision_dir(revision, root)
        end
      end
    end
  end
end
