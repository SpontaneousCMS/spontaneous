module Spontaneous::Publishing::Steps
  class ActivateRevision < BaseStep

    def count
      2
    end

    def call
      save_state
      @progress.stage("activating revision")
      set_published_revision
      symlink_revision(revision)
    end

    def rollback
      @site.send(:set_published_revision, @state.published_revision)
      if @linked
        symlink_path(@linked)
      else
        FileUtils.rm(@site.revision_dir) if File.exist?(@site.revision_dir)
      end
    end

    def set_published_revision
      @site.send(:set_published_revision, revision)
      @progress.step(1, "published revision => #{revision}")
    end

    def symlink_revision(r)
      path = @site.revision_dir(r)
      symlink_path(path)
      @progress.step(1, %(symlinking "revisions/current" => "#{path}"))
    end

    def symlink_path(path)
      system("ln -nsf #{path} #{@site.revision_dir}")
    end

    def save_state
      @state = @site.state
      link = Pathname.new(@site.revision_dir)
      @linked = link.realpath.to_s if link.exist?
    end
  end
end
