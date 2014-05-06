
module Spontaneous::Publishing
  class Publish
    attr_reader :site, :revision, :actions

    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def publish_pages(modified_pages)
      pages = normalise_page_list(modified_pages)
      if all_pages?(pages) || all_modified_pages?(pages)
        publish_all
      else
        pages = Spontaneous::Change.include_dependencies(pages)
        publish(pages)
      end
    end

    def publish_all
      publish(nil)
    end

    def publish(pages)
      model.database.transaction do
        publish!(pages)
      end
    rescue Exception => e
      abort_publish(e)
      raise
    end

    def publish!(pages)
      start_publish
      model.publish(revision, pages) do
        run_pipeline(pages)
      end
      finish_publish
    end

    def run_pipeline(pages)
      model.scope(revision, true) do
        run_pipeline!(pages)
      end
    end

    def run_pipeline!(pages)
      pages ||= all_unpublished_pages
      pipeline.run(site, revision, pages, progress)
    end

    def pipeline
      @pipeline ||= Pipeline.new(actions.steps)
    end

    def start_publish
      progress.log("Publishing revision #{revision}")
      # when working with multiple instances it's possible to rollback the revision number
      # leaving behind old revisions > the current published_revision.
      model.delete_revision(revision)
      site.send(:pending_revision=, revision)
    end

    def finish_publish
      S::PublishedRevision.create(:revision => revision, :published_at => Time.now)
      site.send(:pending_revision=, nil)
      site.must_publish_all!(false)
      progress.done
    end

    def abort_publish(e)
      S::PublishedRevision.filter(:revision => revision).delete
      site.send(:pending_revision=, nil)
      progress.error(e)
    end

    def model
      @site.model
    end

    def progress
      @progress ||= Progress::Multi.new(*actions.progress)
    end

    def normalise_page_list(pages)
      pages = pages.flatten.map { |c|
        c.is_a?(model::Page) ? c.reload : model::Page[c]
      }
    end

    def all_unpublished_pages
      @all_unpublished_pages ||= Spontaneous::Change.unpublished_pages(@site)
    end

    def all_pages
      site.pages
    end

    def all_pages?(pages)
      (all_pages - pages).empty?
    end

    def all_modified_pages?(pages)
      (all_unpublished_pages - pages).empty?
    end
  end
end
