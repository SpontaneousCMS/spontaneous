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
      plugin Spontaneous::Plugins::Field::EditorClass

      include ImageFieldUtilities

      def self.accepts
        %w{image/(png|jpeg|gif)}
      end

      def self.size(name, &process)
        self.sizes[name.to_sym] = process

        unless method_defined?(name)
          class_eval <<-IMAGE
            def #{name}
              sizes[:#{name}]
            end
            IMAGE
        end
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

      def sizes
        @sizes ||= Hash.new { |hash, key| hash[key] = ImageAttributes.new(processed_values[key]) }
      end

      # value used to show conflicts between the current value and the value they're attempting to enter
      def conflicted_value
        value
      end

      # original is special and should always be defined
      def original
        @original ||= sizes[:original]
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

      # formats are irrelevant to image/file fields
      def outputs
        [:original].concat(self.class.size_definitions.map { |name, process| name })
      end

      def value(format=:html, *args)
        sizes[:original].src
      end

      def generate(output, image_path)
        return { :src => image_path } unless File.exist?(image_path)
        image = ImageProcessor.new(image_path)
        result = \
          case output
          when :original
            image
          else
            process = self.class.size_definitions[output]
            image.apply(process, output)
          end
        result.serialize
      end

      def preprocess(image_path)
        filename = nil
        case image_path
        when Hash
          filename = image_path[:filename]
          image_path = image_path[:tempfile].path
        when String
          # return image_path unless File.exist?(image_path)
        end
        return image_path unless File.exist?(image_path)
        media_path = owner.make_media_file(image_path, filename)
        set_unprocessed_value(File.expand_path(media_path))
        media_path
      end

      def export(user = nil)
        super(user).merge({
          :processed_value => processed_values
        })
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

      def inspect
        %(<#{self.class.name}: src=#{src.inspect} width="#{width}" height="#{height}">)
      end
    end

    class ImageProcessor
      include ImageFieldUtilities

      class ImageDelegator < Spontaneous::ProxyObject
        attr_reader :image

        def initialize(image)
          @image = image
        end

        def format(*args, &block)
          image.format(*args, &block)
        end

        def fit(width, height)
          image.combine_options do |c|
            c.add(:geometry, "#{width}x#{height}>")
          end
        end

        def crop(width, height)
          image.combine_options do |c|
            dimensions = "#{width}x#{height}"
            c.add(:geometry, "#{dimensions}^")
            c.add(:gravity, "center")
            c.add(:crop, "#{dimensions}+0+0!")
          end
        end

        def width(width)
          image.combine_options do |c|
            c.add(:geometry, "#{width}x>")
          end
        end

        def height(height)
          image.combine_options do |c|
            c.add(:geometry, "x#{height}>")
          end
        end

        def greyscale
          image.combine_options do |c|
            c.add(:type, "Grayscale")
          end
        end

        def border_radius(radius, bg_color = nil)
          @image.format('png') if bg_color.nil? or bg_color == 'transparent'
          puts @image.path
          c = MiniMagick::CommandBuilder.new('convert')
          c << @image.path
          c.add(:format, "roundrectangle 0,0 %[fx:w-1],%[fx:h-1], 10,10")
          c.add(:write, "info:tmp.mvg")
          c << @image.path

          puts c.command
          # @image.run(c)
          sub = Subexec.run(c.command, :timeout => MiniMagick.timeout)

          c = MiniMagick::CommandBuilder.new('convert')

          c << @image.path
          # c.add(:write, "info:tmp.mvg")
          c.add(:matte)
          c.add(:bordercolor, "none")
          c.add(:border, "0")
          c.push('\\(')
          c.push("+clone")
          c.add(:alpha, 'transparent')
          c.add(:background, 'white')
          c.add(:fill, 'white')
          c.add(:stroke, 'none')
          c.add(:strokewidth, '0')
          c.add(:draw, "@tmp.mvg")
          c.push('\\)')
          c.add(:compose, 'DstIn')
          c.add(:composite)
          c << @image.path
          puts c.command
          @image.run(c)

        end


        def __run__(process)
          instance_eval(&process)
        end

        def method_missing(method, *args, &block)
          if image.respond_to?(method)
            image.__send__(method, *args, &block)
          else
            image.method_missing(method, *args, &block)
          end
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

      def apply(process, name)
        image = ::MiniMagick::Image.open(path)
        processor = ImageProcessor::ImageDelegator.new(image)
        processor.__run__(process)
        file_path = filename_for_size(name, image)
        image.write(file_path)

        ImageProcessor.new(file_path)
      end

      def filename_for_size(name, image)
        directory = File.dirname(path)
        original_filename = File.basename(path)
        parts = original_filename.split('.')
        ext = File.extname(image.path)[1..-1]
        # ext = parts[-1]
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
