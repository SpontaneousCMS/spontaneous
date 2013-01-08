# encoding: UTF-8

require 'digest/sha1'

module Spontaneous
  module Media

    autoload :File,     "spontaneous/media/file"
    autoload :TempFile, "spontaneous/media/temp_file"

    include Spontaneous::Constants

    extend self

    def media_path(*args)
      ::File.join(Spontaneous.media_dir, *args)
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

    def combine_shards(hashes, &block)
      hashes = hashes.split(',') unless hashes.is_a?(Array)
      shards = hashes.map { |hash| Spontaneous.shard_path(hash) }
      Tempfile.open('shard') do |combined|
        combined.binmode

        shards.each do |shard|
          ::File.open(shard, 'rb') do |part|
            while data = part.read(131072)
              combined.write(data)
            end
          end
        end
        combined.flush
        combined.rewind
        yield(combined) if block_given?
      end
    end

  end
end
