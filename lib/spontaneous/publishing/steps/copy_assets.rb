module Spontaneous::Publishing::Steps
  class CopyAssets < BaseStep

    def count
      assets.length
    end

    def call
      progress.stage("copying assets")
      assets.each do |logical_path, absolute_path|
        copy_asset(logical_path, absolute_path)
        progress.step(1, "'#{logical_path}'")
      end
    end

    def rollback
    end

    def copy_asset(logical_path, absolute_path)
      return unless File.exist?(absolute_path)
      transaction.store_asset(logical_path, ::File.binread(absolute_path))
    end

    def make_absolute(path)
      ::File.join('/', path)
    end

    def assets
      manifest.assets
    end

    def manifest
      transaction.asset_manifests
    end

    def development?
      Spontaneous.development?
    end
  end
end
