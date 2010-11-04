
module Spontaneous
  class Media
    class << self

      def media_path(*args)
        File.join(Spontaneous.media_dir, *args)
      end

      @@upload_uid_lock  = Mutex.new
      @@upload_uid_index = 0

      def upload_index
        @@upload_uid_lock.synchronize do
          @@upload_uid_index = (@@upload_uid_index + 1) % 0xFFFFFF
        end
      end

      def upload_path(filename)
        time = Time.now.to_i
        dir = "#{time}.#{upload_index}"
        Spontaneous.media_path("tmp", dir, filename)
      end

      def to_urlpath(filepath)
        filepath.gsub(%r{^#{Spontaneous.media_dir}}, "/media")
      end

      def to_filepath(urlpath)
        urlpath.gsub(%r{^/media}, Spontaneous.media_dir)
      end
    end
  end
end
