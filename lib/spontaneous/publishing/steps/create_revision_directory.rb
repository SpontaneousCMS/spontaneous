# Should be called *after* the revision
module Spontaneous::Publishing::Steps
  class CreateRevisionDirectory < BaseStep

    def call
      progress.stage("creating revision directory")
      transaction.validate_output_store
      FileUtils.mkdir_p(path / "tmp")
      progress.step(count, path)
    end

    def count
      1
    end

    # This is the reason for the existance of this step: cleaning up when it's gone wrong
    def rollback
      FileUtils.rm_r(path) if File.exist?(path)
      transaction.rollback
    end

    def path
      site.revision_dir(revision)
    end
  end
end
