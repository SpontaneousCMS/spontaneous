# Should be called *after* the revision
module Spontaneous::Publishing::Steps
  class WriteRevisionFile < BaseStep

    def call
      @progress.stage("writing revision file")
      save_state
      padded_revision = Spontaneous::Paths.pad_revision_number(revision)
      write_revision_file(padded_revision)
      @progress.step(count, "#{path.inspect} => #{padded_revision.inspect}")
    end

    def count
      1
    end

    def rollback
      if @previous
        write_revision_file(@previous)
      else
        FileUtils.rm(path)
      end
    end

    def write_revision_file(contents)
      File.open(path, "w:UTF-8") do |file|
        file.write(contents)
      end
    end

    def path
      @site.revision_root / "REVISION"
    end

    def save_state
      @previous = if File.exist?(path)
        File.read(path)
      else
        nil
      end
    end
  end
end
