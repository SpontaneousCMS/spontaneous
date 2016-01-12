# encoding: UTF-8

require 'set'

module Spontaneous::Model::Action
  # Designed to be run after any schema modifications that delete types or boxes
  # this action deletes all instances with invalid type ids and then cleans
  # up the remaining content by testing the visibility path of each remaining instance
  # and deletes any that are 'orphaned' i.e. they have a hole in their ancestry.
  #
  # This would normally be managed by the recursive destroy but when we're dealing
  # with content that has no matching schema type it's hard to instantiate them & hence
  # hard to invoke a destroy (and we resort to db level deletes)
  #
  # This is an argument for moving hierarcy maintenance into db level triggers
  # rather than keeping them at the ORM level.
  class Clean
    extend Spontaneous::Concern

    def self.run(site)
      new(site).run
    end

    attr_reader :stats

    def initialize(site)
      @site  = site
      @model = site.model
      @dirty = false
    end

    def run
      stats = {}
      @model.db.transaction do
        stats[:invalid] = delete_invalid_type_instances
        stats[:orphans] = delete_orphans
        stats[:publish] = configure_force_publish
      end
      stats
    end

    # Delete all instances whose schema id is invalid
    def delete_invalid_type_instances
      invalid = mapper.filter(nil).invert
      count   = delete(invalid)
      @dirty ||= (count > 0)
      count
    end

    def delete(ds)
      # TODO: as for UID#after_destroy the list of associations should be
      # automatically generated, rather than hand-crafted
      associations = [[Spontaneous::PageLock, :content_id]]
      ids = ds.ds.map { |row| row[:id] }
      associations.each do |model, column|
        model.filter(column => ids).delete
      end
      ds.delete
    end

    # Delete all orphaned content items i.e. entries that have an ancestor
    # who is missing, probably as a result of a schema type deletion
    def delete_orphans
      count = 0
      mapper.dataset.each do |content|
        unless valid_path?(content)
          content.destroy
          count += 1
        end
      end
      @dirty ||= (count > 0)
      count
    end

    # If we've deleted content items at the db level then we need to force
    # a full publish to reset our change tracking and make sure the live
    # site is a proper reflection of the edited content
    def configure_force_publish
      @site.must_publish_all! if @dirty
      @site.must_publish_all?
    end

    # Use our set of existing ids to check that every entry in an instance's
    # visibility path exists.
    def valid_path?(content)
      content.visibility_ancestor_ids.all? { |id| existing_ids.include?(id) }
    end

    # Get the id of every valid instance in the db
    def existing_ids
      @existing_ids ||= Set.new(mapper.select(nil, :id).map{ |row| row[:id] })
    end

    def mapper
      @model.mapper
    end
  end
end
