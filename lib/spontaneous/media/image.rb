module Spontaneous::Media
  module Image
    autoload :Attributes, "spontaneous/media/image/attributes"
    autoload :Format,     "spontaneous/media/image/format"
    autoload :Optimizer,  "spontaneous/media/image/optimizer"
    autoload :Processor,  "spontaneous/media/image/processor"
    autoload :Renderable, "spontaneous/media/image/renderable"
    autoload :Skeptick,   "spontaneous/media/image/skeptick"

    def self.dimensions(file)
      new(file).dimensions
    end

    def self.type(file)
      new(file).format
    end

    def self.format(file)
      new(file).format
    end

    def self.identify(file)
      new(file)
    end

    def self.header_size
      formats.map { |magic, _| magic.length }.max
    end

    def self.peek(file)
      file.read(header_size).unpack("C*")
    end

    def self.formats
      @formats ||= {}
    end

    def self.define(ext, magic, &block)
      formats[ext] = [magic, block]
    end

    def self.new(file)
      Format.new(file)
    end
  end

  JPEG_MARKER = [
    "\xc0", "\xc1", "\xc2", "\xc3",
    "\xc5", "\xc6", "\xc7",
    "\xc9", "\xca", "\xcb",
    "\xcd", "\xce", "\xcf",
  ].map { |c| c.unpack('C').first }.freeze

  Image.define :gif, [71, 73, 70, 56] do |file|
    file.seek(6)
    file.read(4).unpack('vv')
  end

  Image.define :png, [137, 80, 78, 71, 13, 10, 26, 10] do |file|
    file.seek(16)
    file.read(8).unpack('NN')
  end

  Image.define :jpg, [255, 216] do |file|
    height = width = 0
    c_marker = 255 # Section marker.
    file.seek(2)
    while(true)
      marker, code, length = file.read(4).unpack('CCn')
      raise "Invalid JPG file: marker not found! '#{file.path}'" if marker != c_marker

      if JPEG_MARKER.include?(code)
        height, width = file.read(5).unpack('xnn')
        break
      end
      file.seek(length - 2, IO::SEEK_CUR)
    end
    [width, height]
  end

  Image.define :webp, [82, 73, 70, 70, nil, nil, nil, nil, 87, 69, 66, 80] do |file|
    file.seek(12)
    format = file.read(4)
    height = width = 0
    uint24 = lambda { |bytes| (bytes + 0.chr).unpack("V").first }

    # The width & height are for the two 'simple' formats
    # are encoded in 14 bit unsigned integers - 14 bit!! WTF
    case format
    when "VP8 " #simple-file-format-lossy
      file.seek(10, IO::SEEK_CUR)
      header = file.read(4).unpack("v*")
      width, height = header.map { |n| n & 0x3fff }
    when "VP8L" #simple-file-format-lossless
      file.seek(5, IO::SEEK_CUR)
      header = file.read(4).unpack("v*")
      width  = (header[0] & 0x3fff) + 1
      height = (header[0] >> 14) + ((header[1] & 0xfff) << 2) + 1
    when "VP8X" #extended-file-format
      file.seek(8, IO::SEEK_CUR)
      width  = uint24[file.read(3)] + 1
      height = uint24[file.read(3)] + 1
    end
    [width, height]
  end
end


