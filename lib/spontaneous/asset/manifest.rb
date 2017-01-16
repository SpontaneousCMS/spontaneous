module Spontaneous::Asset
  class Manifest
    attr_reader :root

    def initialize(root)
      @root = root
    end

    def match?(path)
      manifest.key?(path)
    end

    def lookup(path)
      return path unless manifest.key?(path)
      manifest[path]
    end

    def path(path)
      return path unless manifest.key?(path)
      logical = manifest[path]
      ::File.join(root, logical)
    end

    def assets
      Hash[manifest.values.map { |asset| [asset, absolute_path(asset)] }]
    end

    def manifest
      @manifest ||= generate_manifest
    end

    def generate_manifest
      return {} unless has_manifest?
      parse_manifest(read_manifest)
    end

    def parse_manifest(manifest_json)
      begin
        JSON.parse(manifest_json)
      rescue => e
        $stderr.puts "Got error parsing manifest file #{manifest_path} #{e}"
        {}
      end
    end
    def read_manifest
      ::File.read(manifest_path)
    end

    def has_manifest?
      ::File.exist?(manifest_path)
    end

    def manifest_path
      absolute_path('manifest.json')
    end

    def absolute_path(asset)
      ::File.join(root, asset)
    end
  end
end
