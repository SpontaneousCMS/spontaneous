# encoding: UTF-8

module Spontaneous::Storage
  class Local < Backend
    attr_reader :root

    def initialize(root_directory, url_path, accepts = nil)
      @root, @url_path, @accepts = ::File.expand_path(root_directory), url_path, accepts
    end

    def copy(existing_file, media_path, mimetype)
      dest_path = create_absolute_path(media_path)
      if existing_file.respond_to?(:read)
        File.open(dest_path, "wb") do |f|
          f.binmode
          while chunk = existing_file.read(8192)
            f.write(chunk)
          end
        end
      else
        FileUtils.copy_file(existing_file, dest_path)
      end
    end

    def open(relative_path, mimetype, mode, &block)
      dest_path = create_absolute_path(relative_path)
      File.open(dest_path, mode) do |f|
        f.binmode
        block.call(f)
      end
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
      File.join(@url_path, join_path(path))
    end

    def local?
      true
    end
  end
end
