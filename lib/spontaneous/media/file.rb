# encoding: UTF-8

require 'fileutils'

module Spontaneous::Media
  class File
    F = ::File

    attr_reader :filename, :owner

    def initialize(owner, filename, mimetype = nil)
      @owner, @filename, @mimetype = owner, Spontaneous::Media.to_filename(filename), mimetype
    end

    def rename(new_filename)
      self.class.new(owner, new_filename, mimetype)
    end

    def open(mode = 'wb', &block)
      storage.open(storage_path, mimetype, mode, &block)
    end

    def copy(existing_file)
      storage.copy(existing_file, storage_path, mimetype)
    end

    def url
      storage.public_url(storage_path)
    end

    def mimetype
      @mimetype ||= ::Rack::Mime.mime_type(ext)
    end

    def ext
      F.extname(filename)
    end

    def storage
      @storage ||= Spontaneous::Site.storage(mimetype)
    end

    def padded_id
      owner.media_id.to_s.rjust(5, "0")
    end

    def padded_revision
      Spontaneous::Site.working_revision.to_s.rjust(4, "0")
    end

    def media_dir
      F.join(padded_id, padded_revision)
    end

    def storage_path
      [padded_id, padded_revision, filename]
    end

    def relative_path
      F.join(*storage_path)
    end

    def path
      F.join(storage.root, relative_path)
    end

    def dirname
      F.join(storage.root, media_dir)
    end

    alias_method :filepath, :path
  end
end
