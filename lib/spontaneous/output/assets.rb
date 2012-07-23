module Spontaneous
  module Output
    module Assets
      extend self

      def compress_js(file_paths, options={})
        Compression.compress_js(file_paths, options)
      end

      def url(file = nil)
        Spontaneous::Output.asset_url(file)
      end

      def path_for(revision, path = nil)
        File.join [Spontaneous::Output.asset_path(revision), path].compact
      end

      def find_file(*relative_paths)
        relative_paths.flatten!
        Spontaneous.instance.paths.expanded(:public).each do |root|
          relative_paths.each do |relative_path|
            path = root / relative_path
            return path if ::File.exist?(path)
          end
        end
        nil
      end

      autoload :Compression, "spontaneous/output/assets/compression"
    end
  end
end
