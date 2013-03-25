# encoding: UTF-8

require 'fileutils'

module Spontaneous::Media
  class File
    F = ::File

    attr_reader :filename, :owner, :source

    def initialize(owner, filename, mimetype = nil)
      @owner, @filename, @mimetype = owner, Spontaneous::Media.to_filename(filename), mimetype
    end

    def rename(new_filename)
      self.class.new(owner, new_filename, nil)
    end

    def open(mode = 'wb', &block)
      storage.open(storage_path, mimetype, mode, &block)
    end

    def copy(existing_file)
      @source = existing_file.respond_to?(:path) ? existing_file.path : existing_file
      storage.copy(existing_file, storage_path, mimetype)
      self
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

    alias_method :extname, :ext

    def filesize
      F.size(source)
    end

    def storage
      @storage ||= Spontaneous::Site.storage(mimetype)
    end

    def padded_id
      Spontaneous::Media.pad_id(owner.media_id)
    end

    def padded_revision
      Spontaneous::Media.pad_revision(revision)
    end

    def revision
      Spontaneous::Site.working_revision
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

    def serialize
      { :url => url, :type => mimetype, :filename => filename }
    end
  end
end
