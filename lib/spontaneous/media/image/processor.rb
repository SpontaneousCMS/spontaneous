module Spontaneous::Media::Image
  class Processor
    include Spontaneous::Media::Image::Skeptick

    def initialize(input, output)
      @input, @output = input, output
    end

    def apply(process)
      if imagemagick_installed?
        cmd = convert(@input, :to => @output, &process)
        cmd.run
      else
        logger.warn("Unable to re-size image, Imagemagick is not installed.")
        FileUtils::Verbose.cp(@input, @output)
      end
    end

    def optimize!
    end

    def imagemagick_installed?
      Kernel.system('which convert >/dev/null 2>&1')
    end
  end
end
