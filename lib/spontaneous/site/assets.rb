# encoding: UTF-8

class Spontaneous::Site
  module Assets
    extend Spontaneous::Concern

    # Url that hosts our compiled assets
    def asset_mount_path
      '/assets'.freeze
    end

    def asset_manifests
      Spontaneous::Asset::Manifests.new(paths(:compiled_assets), asset_mount_path)
    end
  end
end
