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

    def initialize(root)
      @root = root
    end

    def add_revision(revision, keys)
      ensure_dir revision_path(revision)
    end

    def revisions
      dirs = ::Dir.entries(@root).select { |dir| /^[0-9]+$/ === dir }
      dirs.map { |dir| dir.to_i(10) }.sort
    end

    def delete_revision(revision, keys = nil)
      if (dir = revision_path(revision)) && ::File.exist?(dir)
        ::FileUtils.rm_r(dir)
      end
    end

    def activate_revision(revision, keys = nil)
      return remove_active_revision if revision.blank?
      if (dir = revision_path(revision)) && F.exist?(dir)
        system("ln -nsf #{dir} #{current_path}")
        F.open(revision_file_path, 'w') { |f| f.write(Spontaneous::Paths.pad_revision_number(revision)) }
      end
    end

    def current_revision
      return nil unless F.exist?(revision_file_path)
      Integer(F.read(revision_file_path), 10)
    end

    protected

    def store(revision, partition, key, template, transaction)
      ::File.open(path!(revision, partition, key, transaction), 'wb') { |f| f.write(template) }
    end

    def load(revision, partition, key)
      read(path(revision, partition, key))
    end

    def read(path)
      return nil unless ::File.exist?(path)
      ::File.open(path, 'r:UTF-8')
    end

    def pad_revision(revision)
      revision.to_s.rjust(5, "0")
    end

    def path!(revision, partition, key, transaction)
      ensure_path path(revision, partition, key, transaction)
    end

    def path(revision, partition, path, transaction = nil)
      transaction.push(key(revision, partition, path)) if transaction
      ::File.join(revision_path(revision), partition, path)
    end

    def revision_path(revision)
      ::File.join(@root, pad_revision(revision))
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

    def ensure_path(path)
      ensure_dir ::File.dirname(path)
      path
    end

    def ensure_dir(dir)
      FileUtils.mkdir_p(dir) unless ::File.exist?(dir)
      dir
    end

    def key(revision, partition, path)
      ::File.join(pad_revision(revision), partition, path)
    end
  end
end