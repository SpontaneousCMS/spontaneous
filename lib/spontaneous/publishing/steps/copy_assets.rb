module Spontaneous::Publishing::Steps
  class CopyAssets < BaseStep

    def count
      # return 0 if development?
      assets.length
    end

    def call
      progress.stage("copying assets")
      assets.each do |logical_path, asset|
        copy_asset(asset)
        progress.step(1, "'#{logical_path}' => '#{asset}'")
      end
    end

    def rollback
    end

    def copy_asset(asset)
      source = File.join(manifest.asset_compilation_dir, asset)
      copy_asset_file(source, asset)
    end

    def copy_asset_file(source, asset)
      return unless File.exist?(source)
      transaction.store_asset(make_absolute(asset), ::File.binread(source))
    end

    def make_absolute(path)
      ::File.join('/', path)
    end

    def assets
      manifest.assets
    end

    def manifest
      environment.manifest
    end

    def environment
      transaction.asset_environment
    end

    def development?
      Spontaneous.development?
    end
  end
end
