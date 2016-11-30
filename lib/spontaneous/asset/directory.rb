module Spontaneous::Asset
  class Directory
    # Recognises a file as a viable asset when it exists within the given root

    attr_reader :root

    def initialize(root)
      @root = root
    end

    def match?(path)
      ::File.exist?(asset_path(path))
    end

    def lookup(path)
      path
    end

    def path(path)
      ::File.join(root, path)
    end

    def assets
      Hash[paths.map { |abs_path| [relative_path(abs_path), abs_path] }]
    end

    def paths
      Dir["#{root}/**/*.*"].reject { |path| /manifest\.json$/ === path }
    end

    def asset_path(path)
      ::File.join(root, path)
    end

    def relative_path(abs_path)
      abs_path[(root.length + 1)..-1]
    end
  end
end
