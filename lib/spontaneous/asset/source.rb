require 'pathname'

module Spontaneous::Asset
  class Source
    def initialize(source_dir)
      @source_dir = ::File.expand_path(source_dir)
    end

    def source_path
      @source_path ||= Pathname.new(@source_dir)
    end

    def source_files
      source_paths.map(&:to_s)
    end

    def source_paths
      @source_files ||= find_source_paths
    end

    def find_source_paths
      absolute_paths = Dir[@source_dir / "**/*.*"].map { |path| Pathname.new(path) }
      source_path = self.source_path
      absolute_paths.map { |path| path.relative_path_from(source_path) }
    end
  end
end

