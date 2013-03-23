module Spontaneous::Media::Image
  class Format
    def initialize(image, attributes = nil)
      @image, @attributes = image, attributes
    end

    def format
      attributes[:format]
    end

    def dimensions
      attributes[:dimensions]
    end

    def size
      attributes[:filesize]
    end

    def src
      [:src, :path].each do |m|
        return @image.send(m) if @image.respond_to?(m)
      end
      @image
    end

    def attributes
      @attributes ||= read_attributes
    end

    def serialize
      attributes.merge(:format => format.to_s)
    end

    def inspect
      %(#<Spontaneous::Media::Image::#{format.to_s.upcase} #{size}B #{dimensions.join("x")} #{src}>)
    end

    private

    def read_attributes
      open do |file|
        analyze(file)
      end
    end

    def analyze(file)
      size = file.size
      return to_attributes(nil) if size == 0
      header = Spontaneous::Media::Image.peek(file)
      file.rewind
      Spontaneous::Media::Image.formats.each do |format, (magic, dim)|
        bytes = header[0, magic.length].zip(magic)
        if bytes.all? { |b, m| m.nil? || b == m }
          return to_attributes(format, size, dim.call(file))
        end
      end
      to_attributes(:unknown, size)
    end

    def to_attributes(format, size = 0, dimensions = [0,0])
      { :format => format, :filesize => size, :dimensions => dimensions,
        :width => dimensions[0], :height => dimensions[1] }
    end

    def open(&block)
      if @image.respond_to?(:read) # IO
        yield @image
      elsif @image.respond_to?(:open) # Media::File
        @image.open do |file|
          block.call(file)
        end
      else # Probably string
        File.open(@image, 'rb') do |file|
          block.call(file)
        end
      end
    end
  end
end
