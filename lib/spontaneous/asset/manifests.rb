module Spontaneous::Asset
  class Manifests
    attr_reader :roots, :mount_point

    def initialize(roots, mount_point)
      @roots = roots.map { |r| File.expand_path(r) }
      @mount_point = mount_point
    end

    def manifests
      @manifests ||= [
        roots.map { |root| Manifest.new(root)  },
        roots.map { |root| Directory.new(root) },
      ].flatten
    end

    # Can we find the given abstract path?
    def match?(path)
      manifest = manifests.detect { |m| m.match?(path) }
      !manifest.nil?
    end

    # Map an abstract path to a compiled version
    def lookup(path)
      manifest = manifests.detect { |m| m.match?(path) }
      if manifest && (asset = manifest.lookup(path))
        return mount(asset)
      end
      path
    end

    def path(path)
      manifest = manifests.detect { |m| m.match?(path) }
      if manifest && (file = manifest.path(path))
        return file
      end
    end

    # A list of all our asset files
    def assets
      uniq = {}
      sets = manifests.map(&:assets)
      sets.each do |assets|
        assets.each do |rel_path, abs_path|
          uniq[rel_path] = abs_path unless uniq.key?(rel_path)
        end
      end
      uniq
    end

    def mount(path)
      return ::File.join(mount_point, path)
    end
  end
end
