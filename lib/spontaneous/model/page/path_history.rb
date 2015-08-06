# encoding: UTF-8

module Spontaneous::Model::Page
  module PathHistory
    extend Spontaneous::Concern

    included do
      one_to_many :path_history, class: Spontaneous::PagePathHistory, key: :page_id, order: Sequel.desc(:revision)

      Spontaneous::PagePathHistory.many_to_one :page, class: model, key: :page_id
    end

    protected

    # Create a new path history entry unless the given paths are identical.
    def save_path_history(old_path, current_path, revision)
      update_path_history(old_path, revision) if should_save_path_history?(old_path, current_path)
    end

    # Only save a path history entry if the path has been changed and the page
    # has been published at least once.
    def should_save_path_history?(old_path, current_path)
      (old_path != current_path) && !never_published?
    end

    # Creates a new path history entry for the given path & revision unless an
    # entry for the revision already exists in which case we skip any further
    # history entries.
    def update_path_history(old_path, revision)
      unless (history = history_for_revision(revision))
        create_path_history(old_path, revision)
      end
    end

    def create_path_history(old_path, revision)
      Spontaneous::PagePathHistory.create(page_id: id, path: old_path, revision: revision)
    end

    def history_for_revision(revision)
      Spontaneous::PagePathHistory.first(page_id: id, revision: revision)
    end
  end
end

