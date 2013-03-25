module Spontaneous::Media::Image
  class Processor
    include Spontaneous::Media::Image::Skeptick

    def initialize(input, output)
      @input, @output = input, output
    end

    def apply(process)
      cmd = convert(@input, :to => @output, &process)
      cmd.run
    end

    def optimize!
    end
  end
end
