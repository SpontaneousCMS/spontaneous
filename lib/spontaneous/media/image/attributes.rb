module Spontaneous::Media
  module Image
    class Attributes
      include Renderable

      attr_reader  :storage, :filepath, :storage

      def initialize(site, params={})
        @params = params.try(:dup) || {}
        @storage = site.storage(storage_name)
      end

      def serialize
        { src: src, width: width, height: height, dimensions: dimensions, filesize: filesize, storage_name: storage_name }
      end

      def export(user = nil)
        serialize.delete_if { |k, v| v.nil? }
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
