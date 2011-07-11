# encoding: UTF-8


module Spontaneous::Plugins::Page
  module Formats
    module ClassMethods
      def formats(*formats)
        @formats ||= [:html]
        return @formats if formats.nil? or formats.empty?
        set_formats(formats)
      end

      def set_formats(formats)
        @mime_types = {}
        formats = formats.flatten
        mime_type = nil
        @formats = formats.map do |format|
          if format.is_a?(Hash)
            mime_type = format.values.first
            format = format.keys.first
            @mime_types[format.to_sym] = mime_type
          else
            mime_type = ::Rack::Mime.mime_type("#{Spontaneous::DOT}#{format}", nil)
          end
          raise Spontaneous::UnknownFormatException.new(format) unless mime_type
          format.to_sym
        end
      end

      def default_format
        formats.first
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        formats.include?(format)
      end

      def mime_type(format)
        if @mime_types && @mime_types.key?(format)
          @mime_types[format]
        else
          ::Rack::Mime.mime_type("#{Spontaneous::DOT}#{format}")
        end
      end
    end

    module InstanceMethods
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
    end
  end # Formats
end # Spontaneous::Plugins::Page

