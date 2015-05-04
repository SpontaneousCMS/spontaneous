module Spontaneous::Publishing::Steps
  class ActivateRevision < BaseStep

    def count
      3
    end

    def call
      save_state
      progress.stage("activating revision")
      commit_transaction
      set_published_revision
      activate_revision(revision)
    end

    def commit_transaction
      transaction.commit
      progress.step(1, "commiting rendered site => #{revision}")
    end

    def rollback
      previous_revision = @state.published_revision
      site.send(:set_published_revision, previous_revision)
      output_store.revision(previous_revision).activate
    end

    def set_published_revision
      site.send(:set_published_revision, revision)
      progress.step(1, "published revision => #{revision}")
    end

    def activate_revision(r)
      progress.step(1, %(activating revision #{r}))
      output_store.revision(r).activate
    end

    def symlink_path(path)
      system("ln -nsf #{path} #{site.revision_dir}")
    end

    def save_state
      @state = site.state
    end

    def output_store
      site.output_store
    end
  end
end
