# encoding: UTF-8

module Spontaneous
  class Change


    class << self
      def outstanding
        unpublished_changes
      end

      def unpublished_changes
        changes = unpublished_pages.map { |page| Change.new(page) }
      end

      def unpublished_pages
        Spontaneous::Content::Page.filter { (modified_at > last_published_at) | {:first_published_at => nil} }.order(:modified_at.desc).all
      end

      def include_dependencies(page_list)
        changes = page_list.map { |page| Change.new(page) }
        pages = changes.map { |change| change.all_pages }.flatten.uniq
        pages
      end

      def export
        outstanding.map { |change_set| change_set.export }
      end

      def serialise_http(user = nil)
        Spontaneous.serialise_http(export)
      end
    end

    attr_reader :page

    def initialize(page)
      @page = page
    end

    def all_pages
      [page].concat(dependent)
    end

    # Calculates all the pages we would have to publish along with this in order to root
    # this page into the site hierarchy.
    #
    # Returns: a list of dependent pages in ancestor order (ascending depth with root first)
    def dependent
      @dependent ||= page.ancestors.reverse.take_while { |ancestor| ancestor.never_published? }.reverse
    end

    def page_id
      page.id
    end

    def export_page(page)
      { :id => page.id,
        :title => page.title.to_s,
        :depth => page.depth,
        :url => page.path,
        :side_effects => export_side_effects(page),
        :published_at => export_timestamp(page.last_published_at),
        :modified_at => export_timestamp(page.modified_at),
        :update_locks => export_update_locks(page) }
    end

    def export_update_locks(page)
      keys = [:id, :content_id, :field_id, :description]
      page.update_locks.map { |lock|
        Hash[ keys.map { |key| [key, lock.send(key)]} ].update(:created_at => lock.created_at.httpdate)
      }
    end

    def export_side_effects(page)
    side_effects = Hash.new { |h, k| h[k] = [] }
       page.pending_modifications.map do |modification|
         side_effects[modification.type] << {
           :count => modification.count,
           :created_at => export_timestamp(modification.created_at),
           :old_value => modification.old_value,
           :new_value => modification.new_value
         }
      end
      side_effects
    end

    def modified_at
      page.modified_at
    end

    def export_timestamp(timestamp)
      return nil if timestamp.nil?
      timestamp.httpdate
    end

    def export
      export_page(page).merge({
        :dependent => dependent.map { |p| export_page(p) }
      })
    end

    def inspect
      %(#<Spontaneous::Change page=#{page.id} dependent=#{dependent.map(&:id).inspect}>)
    end
  end
end
