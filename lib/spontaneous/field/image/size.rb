module Spontaneous::Field
  class Image
    class Size
      include Spontaneous::Media::Image::Renderable

      attr_reader :path

      def initialize(input, name, options, process)
        @input, @name, @process = input, name, process
        @options = {:optimize => true}.merge(options)
      end

      def generate
        tempfile do |tempfile|
          convert(tempfile)
          file = @input.rename(filename)
          file.copy(tempfile)
          serialize(file)
        end
      end

      def serialize(file)
        values = file.serialize
        path = values.delete(:path)
        src  = values.delete(:url)
        image = Spontaneous::Media::Image.new(file.source)
        values.update(image.attributes).update(:src => src)
      end

      def convert(tempfile)
        processor = Spontaneous::Media::Image::Processor.new(path, tempfile.path)
        processor.apply(process)
        optimize(tempfile) if @options[:optimize]
      end

      def optimize(tempfile)
        Spontaneous::Media::Image::Optimizer.run(tempfile.path)
      end

      def process
        @process || Proc.new {  }
      end

      def path
        @input.source
      end

      def extname
        (format = @options[:format]) ? ".#{format}" : @input.extname
      end

      def tempfile(&block)
        dir  = Dir.mktmpdir
        name = "#{@name}#{extname}"
        path = ::File.join(dir, name)
        ::File.open(path, "w+b") do |file|
          block.call file
        end
      ensure
        FileUtils.rm_rf(dir) rescue nil
      end

      def filename
        original_filename = @input.filename
        parts = original_filename.split('.')
        base = parts[0..-2].join('.')
        size = @name == :original ? "" : ".#{@name}"
        "#{base}#{size}#{extname}"
      end

      def inspect
        %(#<Spontaneous::Field::Image::Size name=:#{@name} options=#{@options.inspect}>)
      end
    end
  end
end
