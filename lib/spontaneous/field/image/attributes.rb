module Spontaneous::Field
  class Image
    class Attributes
      include Utilities

      attr_reader  :src, :width, :height, :filesize, :filepath

      def initialize(params={})
        params ||= {}
        @src, @width, @height, @filesize, @filepath = params[:src], params[:width], params[:height], params[:filesize], params[:path]
      end

      def serialize
        {
          :src => src,
          :width => width,
          :height => height,
          :filesize => filesize,
          :path => filepath
        }
      end

      def inspect
        %(<#{self.class.name}: src=#{src.inspect} width="#{width}" height="#{height}">)
      end

      def blank?
        src.blank?
      end

      alias_method :empty?, :blank?
    end
  end
end
