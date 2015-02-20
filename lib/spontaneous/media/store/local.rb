# encoding: UTF-8

module Spontaneous::Media::Store
  class Local < Backend
    attr_reader :root

    def initialize(name, root_directory, url_path_root, accepts = nil)
      super(name)
      @root, @url_path_root, @accepts = ::File.expand_path(root_directory), url_path_root, accepts
    end

    def copy(existing_file, media_path, headers = {})
      dest_path = create_absolute_path(media_path)
      copy_file(existing_file, dest_path)
      set_permissions(dest_path)
      dest_path
    end

    def copy_file(existing_file, dest_path)
      if existing_file.respond_to?(:read)
        # Re-open the file because it's been modified on disk by the optimisation process
        # and if we don't re-open it the copy will take the unmodified version
        File.open(existing_file.path, "rb") do |src|
          src.binmode
          File.open(dest_path, "wb") do |f|
            f.binmode
            while chunk = src.read(8192)
              f.write(chunk)
            end
          end
        end
      else
        FileUtils.copy_file(existing_file, dest_path)
      end
    end

    def open(relative_path, headers, mode, &block)
      dest_path = create_absolute_path(relative_path)
      File.open(dest_path, mode) do |f|
        f.binmode
        block.call(f)
      end
      set_permissions(dest_path)
    end

    def create_absolute_path(relative_path)
      absolute_path = File.join(root, join_path(relative_path))
      absolute_dir = File.dirname(absolute_path)
      FileUtils.mkdir_p(absolute_dir) unless File.exist?(absolute_dir)
      absolute_path
    end

    def join_path(path)
      File.join(*path)
    end

    def public_url(path)
      File.join(@url_path_root, join_path(path))
    end

    alias_method :url_path, :public_url

    def local?
      true
    end

    def set_permissions(filepath)
      File.chmod(0644, filepath)
    end
  end
end
