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
end

Dir[::File.dirname(__FILE__) + "/image/format/*.rb"].each do |format|
  require format
end
