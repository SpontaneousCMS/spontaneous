
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
      template.result(binding)
    end

    def template
      @template ||= Erubis::Eruby.new(File.read(path))
    end
  end
end
