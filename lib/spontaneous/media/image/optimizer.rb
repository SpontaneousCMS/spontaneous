require 'shellwords'

module Spontaneous::Media::Image
  class Optimizer
    def self.run(source_image)
      self.new(source_image).run
    end

    def self.binary(cmd)
      (@binaries ||={})[cmd] ||= find_binary(cmd)
    end

    def self.find_binary(name)
      binary = `which #{name}`.chomp
      return nil if binary.length == 0
      binary
    end

    def initialize(source_image)
      @image = source_image
    end

    def run
      format = Spontaneous::Media::Image.format(@image)
      if format && respond_to?(format)
        send(format)
      end
    end

    def jpg
      run_optimization("jpegoptim", "-o -q --strip-all --preserve --force #{@image} 2>&1 1>/dev/null")
      # run_optimization("jpegtran", "-optimize -progressive -copy none -outfile #{input} #{input}")
    end

    def png
      # pngcrush refuses to play if the input & output are the same
      Tempfile.open("crushme", :binmode => true) do |temp|
        ::File.open(@image, "rb") { |src| IO.copy_stream(src, temp) }
        run_optimization("pngcrush", "-rem alla -reduce -cc #{temp.path} #{@image}")
      end
    end

    def run_optimization(lib, args)
      exe = binary(lib)
      return unless exe
      command = [exe, args].join(" ")
      logger.debug(command)
      measure do
        process = POSIX::Spawn::Child.new(command)
        unless process.success?
          logger.error("Error optimizing image: #{@image}\n#{process.err}")
        end
        process.status
      end
    end

    def measure
      before, start = ::File.size(@image), Time.now
      result = yield
      after, _end  = ::File.size(@image), Time.now
      logger.debug("#{(100 * (1 - after.to_f/before.to_f)).round(1)}% optimization of '#{::File.basename(@image)}' [#{before} -> #{after}] in #{_end - start}s")
      result
    end

    def binary(cmd)
      self.class.binary(cmd)
    end
  end
end
