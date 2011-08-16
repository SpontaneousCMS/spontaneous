# encoding: UTF-8

require 'mini_magick'

module Spontaneous
  module FieldTypes

    module ImageFieldUtilities
      attr_accessor :template_params

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

    class ImageField < Base
      include ImageFieldUtilities

      def self.accepts
        %w{image/(png|jpeg|gif)}
      end

      def self.size(name, definition)
        self.sizes[name.to_sym] = definition
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
        self.class.size_definitions.each do |name, size|
          attribute_set(name, image.resize(name, size).serialize)
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

      class MiniMagick::CommandBuilder

        def fit(width, height)
          self.add(:geometry, "#{width}x#{height}>")
        end

        def crop(width, height)
          dimensions = "#{width}x#{height}"
          self.add(:geometry, "#{dimensions}^")
          self.add(:gravity, "center")
          self.add(:crop, "#{dimensions}+0+0!")
        end

        def width(width)
          self.add(:geometry, "#{width}x>")
        end

        def height(height)
          self.add(:geometry, "x#{height}>")
        end

        def greyscale
          self.add(:type, "Grayscale")
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

      def resize(name, size)
        image = ::MiniMagick::Image.open(path)
        commands = normalise_commands(size)
        image.combine_options do |c|
          commands.each do |cmd|
            c.send(*cmd)
          end
        end
        file_path = filename_for_size(name)
        image.write(file_path)

        ImageProcessor.new(file_path)
      end

      def normalise_commands(input_commands)
        commands = \
          case input_commands
          when Hash
            input_commands.to_a
          when String
            input_commands.split
          else
            input_commands
          end
        commands.map do |cmd|
          case cmd
          when Array
            # action, *args = cmd
            # [action, args]
            cmd.flatten
          else
            cmd
          end
        end
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

