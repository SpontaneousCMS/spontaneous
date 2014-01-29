# encoding: UTF-8

require 'tempfile'

module Spontaneous::Field
  class File < Base
    has_editor

    # In the case of clearing the field we will have been given a pending_value of ""
    # we don't want that to run asynchronously
    def asynchronous?
      return false if (pending_value && pending_value[:value].blank?)
      true
    end

    def outputs
      [:html, :path, :filesize, :filename]
    end

    def set_pending_value(value, site)
      file = process_upload(value, site)
      pending = case file
        when nil
          ""
        when String
          { :tempfile => file }
        else
          serialize_pending_file(file)
        end
      super(pending, site)
    end

    def page_lock_description
      "Processing file '#{pending_value[:value][:filename]}'"
    end

    def serialize_pending_file(file)
      { :tempfile => file.path, :type => file.mimetype, :filename => file.filename, :filesize => file.filesize, :src => file.url }
    end

    def storage_headers(content_type, filename)
      headers = { content_type: content_type }
      if prototype && prototype.options[:attachment]
        headers.update(content_disposition: %(attachment; filename=#{Rack::Utils.escape(filename)}))
      end
      headers
    end

    def process_upload(value, site)
      return nil if value.blank?
      file, filename, mimetype = fileinfo(value)
      media_file = site.tempfile(self, filename, storage_headers(mimetype, filename))
      media_file.copy(file)
      media_file
    end

    def preprocess(image, site)
      file, filename, mimetype = fileinfo(image)
      return "" if file.nil?
      return file unless ::File.exist?(file)

      media_file = site.file(owner, filename, storage_headers(mimetype, filename))
      media_file.copy(file)
      set_unprocessed_value(media_file.path)
      media_file
    end

    def fileinfo(fileinfo)
      file = filename = mimetype = nil
      case fileinfo
      when Hash
        file, filename, mimetype = fileinfo.values_at(:tempfile, :filename, :type)
      when ::String
        filename = ::File.basename(fileinfo)
        file     = fileinfo
      end
      [file, filename, mimetype]
    end

    def generate_filesize(input, site)
      if input.respond_to?(:filesize)
        input.filesize
      else
        ::File.exist?(input) ? ::File.size(input) : 0
      end
    end

    def generate_filename(input, site)
      if input.respond_to?(:filename)
        input.filename
      else
        ::File.basename(input.to_s)
      end
    end

    def generate_path(input, site)
      return input if input.is_a?(::String)
      input.url
    end

    def generate_html(input, site)
      generate_path(input, site)
    end

    def export(user = nil)
      super(user).merge({
        :processed_value => processed_values
      })
    end

    def path
      value(:html)
    end

    self.register
  end
end
