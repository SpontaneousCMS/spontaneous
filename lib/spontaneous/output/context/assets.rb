module Spontaneous::Output::Context
  module Assets
    def asset_path(path, options = {})
      site.asset_manifests.lookup(path)
    end

    def asset_url(path, options = {})
      "url(#{asset_path(path, options)})"
    end
  end
end
