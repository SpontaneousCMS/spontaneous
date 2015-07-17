
module Spontaneous::Publishing
  class Publish
    attr_reader :site, :revision, :actions

    def initialize(site, revision, actions)
      @site, @revision, @actions = site, revision, actions
    end

    def publish_pages(modified_pages, user = nil)
      pages = normalise_page_list(modified_pages)
      if all_pages?(pages) || all_modified_pages?(pages)
        publish_all(user)
      else
        pages = Spontaneous::Change.include_dependencies(pages)
        publish(pages, user)
      end
    end

    def publish_all(user = nil)
      publish(nil, user)
    end

    def publish(pages, user)
      model.database.transaction do
        publish!(pages, user)
      end
    rescue Exception => e
      abort_publish(e)
      raise
    end

    def publish!(pages, user)
      start_publish(user)
      model.publish(revision, pages) do
        run_pipeline(pages, user)
      end
      finish_publish(user)
    end

    def run_pipeline(pages, user)
      model.scope(revision, true) do
        run_pipeline!(pages, user)
      end
    end

    def run_pipeline!(pages, user)
      pages ||= all_unpublished_pages
      pipeline.run(transaction(pages, user))
    end

    def pipeline
      @pipeline ||= Pipeline.new(actions.steps)
    end

    def transaction(pages, user)
      Transaction.new(site, revision, pages, progress, user)
    end

    def start_publish(user)
      progress.log("Publishing revision #{revision}")
      # when working with multiple instances it's possible to rollback the revision number
      # leaving behind old revisions > the current published_revision.
      model.delete_revision(revision)
      site.send(:pending_revision=, revision)
    end

    def finish_publish(user)
      S::PublishedRevision.create(revision: revision, published_at: Time.now, user: user)
      site.send(:pending_revision=, nil)
      site.must_publish_all!(false)
      progress.done
    end

    def abort_publish(e)
      S::PublishedRevision.filter(revision: revision).delete
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
