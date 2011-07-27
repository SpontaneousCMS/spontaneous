require 'digest/sha1'

module Spontaneous
  class Media
    class << self

      include Spontaneous::Constants

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
        parts = urlpath.split("/")
        parts[1] = Spontaneous.media_dir
        ::File.join(*parts)
      end

      def to_filename(input)
        parts = input.strip.split(/\./)
        ext = parts.last
        name = parts[0..-2].join(DOT)
        name.gsub!(RE_QUOTES, EMPTY)
        name.gsub!(/[^\.A-Za-z0-9_-]+/, DASH)
        name.gsub!(RE_FLATTEN_REPEAT, DASH)
        name.gsub!(RE_FLATTEN_TRAILING, EMPTY)
        [name, ext].join(DOT)
      end


      def sha1(filepath)
        Digest::SHA1.file(filepath).hexdigest
      end

      alias_method :digest, :sha1
    end
  end
end
