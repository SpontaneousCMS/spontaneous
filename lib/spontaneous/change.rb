# encoding: UTF-8

module Spontaneous
  class Change
    class << self
      def outstanding(site)
        outstanding = { :published_revision => site.published_revision, :must_publish_all => site.must_publish_all?,
          :changes => unpublished_changes(site) }
        outstanding[:first_publish] = true if outstanding[:published_revision] == 0
        outstanding
      end

      def unpublished_changes(site)
        changes = unpublished_pages(site).map { |page| Change.new(page) }
      end

      def unpublished_pages(site)
        site.model.with_editable { # published content never has changes...
          site.model::Page.filter(content_hash_changed: true).order(Sequel.desc(:content_hash_changed_at)).all
        }
      end

      def include_dependencies(page_list)
        changes = page_list.map { |page| Change.new(page) }
        pages = changes.map { |change| change.all_pages }.flatten.uniq
        pages
      end

      def export(site)
        exported = {}
        outstanding(site).each do |k, v|
          case k
          when :changes
            exported[k] = v.map { |change_set| change_set.export }
          else
            exported[k] = v
          end
        end
        exported
      end

      def serialise_http(site)
        Spontaneous.serialise_http(export(site))
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
      keys = [:id, :content_id, :field_id, :field_name, :location, :description, :created_at]
      page.update_locks.map { |lock| export_object(lock, keys) }
    end

    def export_side_effects(page)
      keys = [:count, :created_at, :old_value, :new_value]
      side_effects = Hash.new { |h, k| h[k] = [] }
      page.pending_modifications.map { |modification|
        side_effects[modification.type] << export_object(modification, keys)
      }
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

    def export_object(target, keys)
      translate = proc { |value|
        case value
        when Time, Date
          export_timestamp(value)
        else
          value
        end
      }
      Hash[ keys.map { |k| [k, translate[target.send(k)] ] } ]
    end
  end
end
