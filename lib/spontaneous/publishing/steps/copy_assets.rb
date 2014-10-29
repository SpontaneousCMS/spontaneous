module Spontaneous::Publishing::Steps
  class CopyAssets < BaseStep

    def count
      assets.length
    end

    def call
      @progress.stage("copying assets")
      ensure_asset_dir
      assets.each do |logical_path, asset|
        copy_asset(asset)
        @progress.step(1, "'#{logical_path}' => '#{asset}'")
      end
    end

    def rollback
      FileUtils.rm_r(revision_asset) if File.exists?(revision_asset)
    end

    def ensure_asset_dir
      dir = revision_asset
    end

    def copy_asset(asset)
      ['', '.gz'].each do |suffix|
        copy_asset_file(asset + suffix)
      end
    end

    def copy_asset_file(asset)
      source = File.join(manifest.asset_compilation_dir, asset)
      if File.exist?(source)
        dest = ensure_dir File.join(revision_asset, asset)
        link_file(source, dest)
      end
    end

    def link_file(source, dest)
      src_dev = File::stat(source).dev
      dst_dev = File::stat(File.dirname(dest)).dev
      if (src_dev == dst_dev)
        FileUtils.ln(source, dest, :force => true)
      else
        FileUtils.cp(source, dest)
      end
    end

    def revision_asset
      @asset_dest ||= Pathname.new(Spontaneous.revision_dir(revision) / 'assets').tap do |path|
        FileUtils.mkdir_p(path) unless File.exists?(path)
      end
    end

    def ensure_dir(path)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end

    def assets
      manifest.assets
    end

    def manifest
      environment.manifest
    end

    def environment
      @environment ||= Spontaneous::Asset::Environment.publishing(site, revision, development?)
    end

    def development?
      Spontaneous.development?
    end
  end
end
