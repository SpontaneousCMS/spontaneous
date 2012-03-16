require 'net/http'

module Spontaneous::Utils
  class SmushIt
    def self.smush!(path)
      self.new(path).smush!
    end
    attr_reader :src_file

    def initialize(file_path)
      @src_file = file_path
    end

    # Smush the source file in-place
    # In development mode the file isn't available under a public url for smushit to download
    # so we just skip it completely
    def smush!
      p src_file
      return if ::Spontaneous.development?
      ext = File.extname(src_file)
      id = [Time.now.to_i, Time.now.usec].join('-')
      public_filepath = File.join(public_path, "%s-smush%s" % [id, ext])
      FileUtils.cp(src_file, public_filepath)
      filename = File.basename(public_filepath)
      url = Site.public_url(public_url(filename))
      path = "/ysmush.it/ws.php?img=#{::Rack::Utils.escape(url)}&task=#{id}&id=paste1"
      # resp, data = http.get(path, nil)
      data = Net::HTTP.get('www.smushit.com', path)
      data = Spontaneous::JSON.parse(data)
      p data

      if data[:dest]
        smushed = URI(data[:dest])
        p smushed
        # download smushed version to tempfile first in case something stops us downloading
        # it
        Tempfile.open("smushing") do |temp|
          temp.binmode
          Net::HTTP.start(smushed.host, smushed.port) do |http|
            http.request_get(smushed.request_uri) do |response|
              response.read_body do |segment|
                temp.write(segment)
              end
            end
          end
          ::FileUtils.cp(temp.path, src_file)
        end
      end
    rescue Exception => e
      logger.error(e)
    ensure
      FileUtils.rm(public_filepath) if public_filepath and File.exist?(public_filepath)
    end

    def public_path
      Spontaneous.media_path
    end

    def public_url(path)
      Site.default_storage.public_url(path)
    end
  end
end
