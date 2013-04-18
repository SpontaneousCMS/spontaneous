# encoding: UTF-8

require 'tempfile'

module Spontaneous::Field
  class File < Base
    has_editor

    def asynchronous?
      true
    end

    def outputs
      [:html, :filesize, :filename]
    end

    def pending_value=(value)
      file = process_upload(value)
      pending = case file
        when String
          { :tempfile => file }
        else
          serialize_pending_file(file)
        end
      super(pending)
    end

    def page_lock_description
      "Processing file '#{pending_value[:value][:filename]}'"
    end

    def serialize_pending_file(file)
      { :tempfile => file.path, :type => file.mimetype, :filename => file.filename, :src => file.url }
    end

    def preprocess(image)
      file, filename, mimetype = fileinfo(image)
      return "" if file.nil?
      return file unless ::File.exist?(file)

      media_file = Spontaneous::Media::File.new(owner, filename, mimetype)
      media_file.copy(file)
      set_unprocessed_value(media_file.path)
      media_file
    end

    def process_upload(value)
      file, filename, mimetype = fileinfo(value)
      media_file = Spontaneous::Media::TempFile.new(self, filename, mimetype)
      media_file.copy(file)
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

    def generate_filesize(input)
      if input.respond_to?(:filesize)
        input.filesize
      else
        ::File.exist?(input) ? ::File.size(input) : 0
      end
    end

    def generate_filename(input)
      if input.respond_to?(:filename)
        input.filename
      else
        ::File.basename(input.to_s)
      end
    end

    def generate_html(input)
      return input if input.is_a?(::String)
      input.url
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
