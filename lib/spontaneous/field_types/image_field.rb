# encoding: UTF-8

require 'mini_magick'
require 'delegate'

module Spontaneous
  module FieldTypes

    module ImageFieldUtilities
      attr_accessor :template_params

      def render(format=:html, *args)
        case format
        when :html
          to_html(*args)
        else
          value
        end
      end

      def to_html(attr={})
        default_attr = {
          :src => src,
          :width => width,
          :height => height,
          :alt => ""
        }
        default_attr.delete(:width) if width.nil?
        default_attr.delete(:height) if height.nil?
        if template_params && template_params.length > 0 && template_params[0].is_a?(Hash)
          attr = template_params[0].merge(attr)
        end
        if attr.key?(:width) || attr.key?(:height)
          default_attr.delete(:width)
          default_attr.delete(:height)
          if (attr.key?(:width) && !attr[:width]) || (attr.key?(:height) && !attr[:height])
            attr.delete(:width)
            attr.delete(:height)
          end
        end
        attr = default_attr.merge(attr)
        params = []
        attr.each do |name, value|
          params << %(#{name}="#{value.to_s.escape_html}")
        end
        %(<img #{params.join(' ')} />)
      end

      def to_s
        src
      end
    end

    class ImageField < Field
      include ImageFieldUtilities

      def self.accepts
        %w{image/(png|jpeg|gif)}
      end

      def self.size(name, &process)
        self.sizes[name.to_sym] = process
      end

      def self.sizes
        size_definitions
      end

      def self.validate_sizes(sizes)
        sizes
      end

      def self.size_definitions
        @size_definitions ||= {}
      end

      def image?
        true
      end

      def has_attribute?(attribute_name)
        super || self.class.size_definitions.key?(attribute_name)
      end

      def attribute_get(attribute, *args)
        @sizes ||= Hash.new { |hash, key| hash[key] = ImageAttributes.new(attributes[key]) }
        @sizes[attribute].tap do |size|
          size.template_params = args
        end
      end

      # value used to show conflicts between the current value and the value they're attempting to enter
      def conflicted_value
        value
      end

      # original is special and should always be defined
      def original
        @original ||= (attributes.key?(:original) ? attribute_get(:original) : ImageAttributes.new(:src => value))
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

      def src
        original.src
      end


      def filepath
        unprocessed_value
      end

      def process(image_path)
        filename = nil
        case image_path
        when Hash
          filename = image_path[:filename]
          image_path = image_path[:tempfile].path
        when String
          attributes.clear
          return image_path unless File.exist?(image_path)
        else
        end
        image_path = owner.make_media_file(image_path, filename)
        image = ImageProcessor.new(image_path)
        attribute_set(:original, image.serialize)
        self.class.size_definitions.each do |name, process|
          attribute_set(name, image.resize(name, process).serialize)
        end
        set_unprocessed_value(File.expand_path(image_path))
        image.src
      end
    end


    class ImageAttributes
      include ImageFieldUtilities

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
    end

    class ImageProcessor
      include ImageFieldUtilities

      class ImageDelegator < Delegator
        attr_reader :image

        def initialize(image)
          super
          @image = image
        end

        def __getobj__; @image; end
        def __setobj__(obj); @image = obj; end

        def __run__(process)
          combine_options do |c|
            cb = CommandDelegator.new(c)
            cb.__run__(process)
          end
        end
      end

      class CommandDelegator < Delegator
        def initialize(cb)
          super
          @cb = cb
        end

        def __getobj__; @cb; end
        def __setobj__(obj); @cb = obj; end

        def __run__(process)
          instance_eval(&process)
        end

        def fit(width, height)
          add(:geometry, "#{width}x#{height}>")
        end

        def crop(width, height)
          dimensions = "#{width}x#{height}"
          add(:geometry, "#{dimensions}^")
          add(:gravity, "center")
          add(:crop, "#{dimensions}+0+0!")
        end

        def width(width)
          add(:geometry, "#{width}x>")
        end

        def height(height)
          add(:geometry, "x#{height}>")
        end

        def greyscale
          add(:type, "Grayscale")
        end

        def method_missing(method, *args, &block)
          __getobj__.send(method, *args, &block)
        end
      end

      MAX_DIM = 2 ** ([42].pack('i').size * 8) - 1 unless defined?(MAX_DIM)

      attr_reader :path

      def initialize(path)
        @path = File.expand_path(path)
      end

      def src
        @src ||= \
          begin
            media_dir = Spontaneous.media_dir
            src = path.sub(%r{^#{media_dir}}, '')
            File.join("/#{File.basename(media_dir)}", src)
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
        @dimensions ||= Spontaneous::ImageSize.read(path)
      end

      def resize(name, process)
        image = ::MiniMagick::Image.open(path)
        processor = ImageProcessor::ImageDelegator.new(image)
        processor.__run__(process)
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

      def serialize
        {
          :src => src,
          :width => width,
          :height => height,
          :filesize => filesize,
          :path => path
        }
      end
    end

    ImageField.register(:image, :photo)

  end
end

