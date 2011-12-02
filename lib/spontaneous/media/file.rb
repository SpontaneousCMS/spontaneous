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

    def copy(existing_file)
      storage.copy(existing_file, relative_path, mimetype)
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

    def relative_path
      F.join(media_dir, filename)
    end

    def url
      F.join(storage.url, relative_path)
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
