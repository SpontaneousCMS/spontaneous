# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Revisions
    extend ActiveSupport::Concern

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

      def revision_root(*path)
        instance.revision_root(*path)
      end

      def revision_dir(revision=nil, root = nil)
        instance.revision_dir(revision, root)
      end
    end # ClassMethods
  end # Revisions
end
