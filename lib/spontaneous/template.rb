
module Spontaneous
  class Template
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def filename
      File.basename(@path)
    end

    def render(binding)
      #should be over-ridden by implementations
    end

  end
end
