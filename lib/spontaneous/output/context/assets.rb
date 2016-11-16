module Spontaneous::Output::Context
  module Assets
    def asset_manifests
      @asset_manifests ||= site.asset_manifests
    end

    def asset_path(path, options = {})
      asset_manifests.lookup(path)
    end

    def asset_url(path, options = {})
      "url(#{asset_path(path, options)})"
    end
  end
end
