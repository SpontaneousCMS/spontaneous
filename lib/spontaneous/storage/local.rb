# encoding: UTF-8

module Spontaneous::Storage
  class Local < Backend
    attr_reader :root

    def initialize(root_directory, url_path, accepts = nil)
      @root, @url_path, @accepts = ::File.expand_path(root_directory), url_path, accepts
    end

    def copy(existing_file, media_path, mimetype)
      dest_path = File.join(root, media_path)
      FileUtils.mkdir_p(File.dirname(dest_path)) unless File.exist?(File.dirname(dest_path))
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

    def url
      @url_path
    end

    def local?
      true
    end
  end
end
