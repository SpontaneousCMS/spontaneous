require 'fileutils'

module Spontaneous::Output::Store
  # The basic template storage backend.
  #
  # It stores static, protected & dynamic templates in different
  # directories so that a reverse proxy conf can be pointed directly
  # at the `static` area and (in theory) protected templates could
  # be served using a "sendfile" header.
  class File < Backend
    F = ::File unless defined? F

    def initialize(config = {})
      super(config)
      @root = config[:root] || config[:dir]
    end

    def add_revision(revision, keys)
      ensure_dir(revision_path(revision)) unless keys.empty?
    end

    def revisions
      dirs = ::Dir.entries(@root).select { |dir| /^[0-9]+$/ === dir }
      dirs.map { |dir| dir.to_i(10) }.sort
    end

    def delete_revision(revision, keys = nil)
      if (dir = revision_path(revision)) && F.exist?(dir)
        FileUtils.rm_r(dir)
      end
    end

    def activate_revision(revision, keys = nil)
      return remove_active_revision if revision.blank?
      if (dir = revision_path(revision)) && F.exist?(dir)
        symlink_revision(revision, dir)
        F.open(revision_file_path, 'w') { |f| f.write(Spontaneous::Paths.pad_revision_number(revision)) }
      end
    end

    def current_revision
      return nil unless F.exist?(revision_file_path)
      Integer(F.read(revision_file_path), 10)
    end

    def load(revision, partition, key, static:)
      read(path(revision, partition, key))
    end

    def store(revision, partition, key, template, transaction)
      F.open(path!(revision, partition, key, transaction), 'wb') { |f| f.write(template) }
    end

    protected

    def read(path)
      return nil unless F.exist?(path)
      F.open(path, 'rb:UTF-8')
    end

    def pad_revision(revision)
      revision.to_s.rjust(5, "0")
    end

    def path!(revision, partition, key, transaction)
      ensure_path path(revision, partition, key, transaction)
    end

    def path(revision, partition, path, transaction = nil)
      transaction.push(key(revision, partition, path)) if transaction
      F.join(revision_path(revision), partition.to_s, path)
    end

    def revision_path(revision)
      F.join(@root, pad_revision(revision))
    end

    def current_path
      F.join(@root, 'current')
    end

    def revision_file_path
      F.join(@root, 'REVISION')
    end

    def remove_active_revision
      FileUtils.rm_f(current_path)
      FileUtils.rm_f(revision_file_path)
    end

    def symlink_revision(revision, revision_dir)
      temp_link = "#{current_path}_#{revision}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
      F.symlink revision_dir, temp_link
      begin
        F.rename temp_link, current_path
      rescue SystemCallError
        F.unlink current_path
        F.rename temp_link, current_path
      end
    ensure
      F.unlink(temp_link) if F.exist?(temp_link)
    end

    def ensure_path(path)
      ensure_dir F.dirname(path)
      path
    end

    def ensure_dir(dir)
      FileUtils.mkdir_p(dir) unless F.exist?(dir)
      dir
    end

    def key(revision, partition, path)
      F.join(pad_revision(revision), partition.to_s, path)
    end
  end
end
