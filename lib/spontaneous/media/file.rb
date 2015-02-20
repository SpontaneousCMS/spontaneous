# encoding: UTF-8

require 'fileutils'

module Spontaneous::Media
  class File
    F = ::File

    attr_reader :filename, :owner, :source

    def initialize(site, owner, filename, headers = {})
      headers = { content_type: headers } if headers.is_a?(String)
      headers ||= {}
      @site, @owner, @filename, @headers = site, owner, Spontaneous::Media.to_filename(filename), headers
    end

    # Create a new File instance with a new name.
    # This new file instance should take its content type from the new name
    # because one of the uses of this is during image size creation where we
    # might be converting from one format to another.
    def rename(new_filename)
      headers = storage_headers
      headers.delete(:content_type)
      self.class.new(@site, owner, new_filename, headers)
    end

    def open(mode = 'wb', &block)
      storage.open(storage_path, storage_headers, mode, &block)
    end

    def copy(existing_file)
      @source = existing_file.respond_to?(:path) ? existing_file.path : existing_file
      storage.copy(existing_file, storage_path, storage_headers)
      self
    end

    def storage_headers
      headers = @headers.dup
      headers[:content_type] ||= mimetype
      headers
    end

    def url
      storage.url_path(storage_path)
    end

    def mimetype
      @mimetype ||= ( @headers[:content_type] || ::Rack::Mime.mime_type(ext) )
    end

    def ext
      F.extname(filename)
    end

    alias_method :extname, :ext

    def filesize
      F.size(source)
    end

    def storage
      @storage ||= @site.storage_for_mimetype(mimetype)
    end

    def padded_id
      Spontaneous::Media.pad_id(owner.media_id)
    end

    def padded_revision
      Spontaneous::Media.pad_revision(revision)
    end

    def revision
      @site.working_revision
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
      { url: url, type: mimetype, filename: filename, storage_name: storage.name }
    end
  end
end
