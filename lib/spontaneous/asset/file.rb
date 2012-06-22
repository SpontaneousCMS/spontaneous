require 'pathname'

module Spontaneous::Asset
  class File
    def initialize(source, relative_path)
      @source, @relative_path = source, relative_path
    end

    def load_path
      [name, extensions.first].join(".")
    end

    def basename
      @basename ||= ::File.basename(@relative_path)
    end

    def name
      basename.split(".").first
    end

    def extensions
      @extensions ||= basename.split(".")[1..-1]
    end
  end
end
