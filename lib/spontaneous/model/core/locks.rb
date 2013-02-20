module Spontaneous::Model::Core
  # Ensure that any page locks belonging to content items are destroyed along
  # with the content.
  #
  # This has to be separate from any page-level deletion because the locks are
  # owned by both and deleting the contents of a box should release locks
  # belonging to them.
  module Locks
    extend Spontaneous::Concern

    def after_destroy
      Spontaneous::PageLock.where(:content_id => id).delete
      super
    end
  end
end
