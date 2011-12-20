# encoding: UTF-8

require 'rack'

module Spontaneous::Plugins::Page
  module Formats
    extend ActiveSupport::Concern

    module ClassMethods
      def formats(*formats)
        return format_list if formats.nil? or formats.empty?
        set_formats(formats)
      end

      def format_list
        @formats ||= supertype_formats
      end

      def mime_types
        @mime_types ||= supertype_mimetypes
      end

      def add_format(new_format)
        format = define_format(new_format)
        format_list.push(format)
      end

      def set_formats(formats)
        formats = formats.flatten
        mime_types.clear
        format_list.clear
        formats.map do |format|
          format_list.push define_format(format)
        end
      end

      def define_format(format)
        mime_type = nil
        if format.is_a?(Hash)
          mime_type = format.values.first
          format = format.keys.first
          mime_types[format.to_sym] = mime_type
        else
          mime_type = ::Rack::Mime.mime_type(".#{format}", nil)
        end
        raise Spontaneous::UnknownFormatException.new(format) unless mime_type
        format.to_sym
      end

      def supertype_formats
        supertype? && supertype.respond_to?(:formats) ? supertype.formats.dup : [:html]
      end

      def supertype_mimetypes
        supertype? && supertype.respond_to?(:mime_types) ? supertype.mime_types.dup : {}
      end

      def default_format
        formats.first
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        formats.include?(format)
      end

      def mime_type(format)
        if mime_types && mime_types.key?(format)
          mime_types[format]
        else
          ::Rack::Mime.mime_type(".#{format}")
        end
      end
    end # ClassMethods

    def formats
      self.class.formats
    end

    def default_format
      self.class.default_format
    end

    def provides_format?(format)
      self.class.provides_format?(format)
    end

    def mime_type(format)
      self.class.mime_type(format)
    end
  end # Formats
end # Spontaneous::Plugins::Page
