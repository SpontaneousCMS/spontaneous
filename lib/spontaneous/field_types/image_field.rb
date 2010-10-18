
module Spontaneous
  module FieldTypes

    class ImageAttributes
      attr_reader  :url, :width, :height, :filesize

      def self.from_file(path)

      end

      def initialize(params={})
        @url, @width, @height, @filesize = params[:url], params[:width], params[:height], params[:filesize]
      end

      def serialize
        {
          :url => url,
          :width => width,
          :height => height,
          :filesize => filesize
        }
      end
    end

    class ImageField < Base


      def self.sizes(sizes={})
        @size_definitions = validate_sizes(sizes)
      end

      def self.validate_sizes(sizes)
        define_attribute :original
        sizes.keys.each do |key|
          define_attribute(key)
        end
        sizes
      end


      def self.size_definitions
        @size_definitions
      end

      def attribute_get(attribute)
        @sizes ||= Hash.new { |hash, key| hash[key] = ImageAttributes.new(attributes[key]) }
        @sizes[attribute]
      end

      def original
        attribute_get(:original)
      end

      def url
        value
      end

      def width
        original.width
      end

      def height
        original.height
      end

      def filesize
        original.filesize
      end

      def url
        original.url
      end

      def filepath
        unprocessed_value
      end

      # takes a path to a newly uploade image in Spontaneous.media_dir
      def process(image_path)
        return image_path unless File.exist?(image_path)
        image = ImageProcessor.new(image_path)
        attribute_set(:original, image.serialize)
        self.class.size_definitions.each do |name, size|
          attribute_set(name, image.resize(name, size).serialize)
        end
        set_unprocessed_value(File.expand_path(image_path))
        image.url
      end

    end

    ImageField.register
  end

  class ImageProcessor
    attr_reader :path

    def initialize(path)
      @path = File.expand_path(path)
    end

    def url
      @url ||= \
        begin
          media_dir = Spontaneous.media_dir
          url = path.sub(%r{^#{media_dir}}, '')
          File.join("/#{File.basename(media_dir)}", url)
        end
    end

    def filesize
      File.size(path)
    end

    def width
      dimensions[0]
    end

    def height
      dimensions[1]
    end

    def dimensions
      @dimensions ||= read_image_dimension
    end

    def read_image_dimension
      Spontaneous::ImageSize.read(path)
    end

    def serialize
      {
        :url => url,
        :width => width,
        :height => height,
        :filesize => filesize
      }
    end

    def resize(name, size)
      image = Miso::Image.new(path)
      [:crop, :fit].each do |method|
        if size.key?(method)
          image.send(method, *size[method])
        end
      end
      if size.key?(:width)
        image.send(:fit, size[:width], nil)
      end
      if size.key?(:height)
        image.send(:fit, nil, size[:height])
      end
      file_path = filename_for_size(name)
      image.write(file_path)

      ImageProcessor.new(file_path)
    end

    def filename_for_size(name)
      directory = File.dirname(path)
      original_filename = File.basename(path)
      parts = original_filename.split('.')
      ext = parts[-1]
      base = parts[0..-2].join('.')
      filename = [base, name, ext].join('.')
      File.join(directory, filename)
    end
  end
end

