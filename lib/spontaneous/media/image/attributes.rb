module Spontaneous::Media
  module Image
    class Attributes
      include Renderable

      attr_reader  :src, :width, :height, :filesize, :filepath

      def initialize(params={})
        params ||= {}
        @src, @width, @height, @filesize, @filepath = params.values_at(:src, :width, :height, :filesize, :path)
      end

      def serialize
        { :src => src, :width => width, :height => height, :filesize => filesize }
      end

      def inspect
        %(<#{self.class.name}: src=#{src.inspect} width="#{width}" height="#{height}">)
      end

      def blank?
        src.blank?
      end

      # Will only work for files in local storage
      def filepath
        Spontaneous::Media.to_filepath(src)
      end

      alias_method :empty?, :blank?

      def value(format = :html)
        src
      end
    end
  end
end
