# encoding: UTF-8

module Spontaneous::Model::Page
  module Locks
    extend Spontaneous::Concern

    included do
      one_to_many :update_locks, :model => Spontaneous::PageLock, :key => :page_id
    end

    def locked_for_update?
      !update_locks.empty?
    end

    def after_destroy
      update_locks_dataset.delete
      super
    end
  end
end
