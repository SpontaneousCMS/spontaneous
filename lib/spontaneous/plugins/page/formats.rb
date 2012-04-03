# encoding: UTF-8

require 'rack'

module Spontaneous::Plugins::Page
  module Formats
    extend ActiveSupport::Concern

    class Format
      attr_reader :format, :mime_type

      def initialize(format, options = {})
        mime_type = nil
        case format
        when String, Symbol
          @format = format.to_sym
          @mime_type = ::Rack::Mime.mime_type(".#{format}", nil)
        when Hash
          @format = format.keys.first.to_sym
          @mime_type = format.values.first
          @dynamic = format[:dynamic]
        end
        @dynamic ||= options[:dynamic] || false
      end

      def renderer_class
        Spontaneous::Render::Format.for(format)
      end

      def ==(other)
        (other.to_sym == self.to_sym) or (other.respond_to?(:format) and (other.format == self.format))
      end

      def eql?(other)
        other.is_a?(Format) and (self == other)
      end

      def hash
        format.to_s.hash
      end

      def to_sym
        format
      end

      def to_s
        format.to_s
      end

      def ext
        ".#{format}"
      end

      def dynamic?
        @dynamic
      end

      def inspect
        %(<Format #{@format}>)
      end
    end

    module ClassMethods
      def format_for(format_name)
        Format.new(format_name)
      end

      def formats(*formats)
        return format_list if formats.nil? or formats.empty?
        set_formats(formats)
      end

      def format_list
        @formats ||= supertype_formats
      end

      def add_format(new_format, *args)
        options = args.extract_options!
        format = define_format(new_format, options)
        format_list.push(format)
      end

      def set_formats(formats)
        formats = formats.flatten
        format_list.clear
        formats.map do |format|
          format_list.push define_format(format)
        end
      end

      def define_format(format, options = {})
        Format.new(format, options).tap do |f|
          raise Spontaneous::UnknownFormatException.new(format) unless f.mime_type
        end
      end

      def supertype_formats
        supertype? && supertype.respond_to?(:formats) ? supertype.formats.dup : [standard_format]
      end

      def standard_format
        Format.new(:html)
      end

      def default_format
        formats.first
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        formats.include?(format)
      end

      def format(format_name = nil)
        return format_name if format_name.is_a?(Format)
        return default_format if format_name.blank?
        format_list.detect { |f| f == format_name } || Format.new(format_name)
      end

      def mime_type(format_name)
        return format_name.mime_type if format_name.respond_to?(:mime_type)
        if (match = format(format_name))
          match.mime_type
        else
          ::Rack::Mime.mime_type(".#{format_name}")
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

    def format(format_name)
      self.class.format(format_name)
    end

    def mime_type(format)
      self.class.mime_type(format)
    end
  end # Formats
end # Spontaneous::Plugins::Page
