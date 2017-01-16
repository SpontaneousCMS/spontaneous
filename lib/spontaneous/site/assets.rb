# encoding: UTF-8

class Spontaneous::Site
  module Assets
    extend Spontaneous::Concern

    # Set the list of commands that will be run in development mode. This
    # should be a hash of command label + proc. The proc should take an output
    # dir param and generate a string suitable for running via `Kernel.system`.
    # The generated commands should be long-running or the whole development
    # environment will exit early.
    def development_watchers=(watchers)
      @development_watchers = watchers
    end

    def development_watchers
      @development_watchers ||= {}
    end

    # Set the list of commands that will be run on deploy. This should be a
    # hash of command label + proc. The proc should take an output dir param
    # and generate a string suitable for running via `Kernel.system`
    def deploy_asset_compilation=(commands)
      @deploy_asset_compilation = commands
    end

    def deploy_asset_compilation
      @deploy_asset_compilation ||= {}
    end

    # Override the default proc that converts a filename into a fingerprinted
    # filename. The given block should take 3 params, a file basename, the md5
    # digest of the file and the extension. For example a file this-logo.png
    # with an md5 digest of ace42403fd86be118b2ac800e0d5f62d will receive the
    # params 'this-logo', 'ace42403fd86be118b2ac800e0d5f62d', '.png'
    def deploy_asset_fingerprint=(block)
      @deploy_asset_fingerprint = block
    end

    def deploy_asset_fingerprint
      @deploy_asset_fingerprint
    end

    # Url that hosts our compiled assets
    def asset_mount_path
      '/assets'.freeze
    end

    def asset_manifests
      Spontaneous::Asset::Manifests.new(paths(:compiled_assets), asset_mount_path)
    end
  end
end
