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
        @params[:src].blank?
      end

      alias_method :empty?, :blank?

      def src
        storage.to_url(@params[:src])
      end

      alias_method :url, :src

      def storage_name
        @params[:storage_name]
      end

      def width
        @params[:width]
      end

      def height
        @params[:height]
      end

      def filesize
        @params[:filesize]
      end

      def dimensions
        @params[:dimensions]
      end

      def filepath
        @params[:path]
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
