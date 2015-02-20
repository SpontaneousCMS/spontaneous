# encoding: UTF-8

require 'fog'
require 'tempfile'

module Spontaneous::Media::Store
  class Cloud < Backend
    # Thanks thoughtbot (via paperclip)
    # http://rdoc.info/github/thoughtbot/paperclip/Paperclip/Storage/Fog
    AWS_BUCKET_SUBDOMAIN_RESTRICTON_REGEX = /^(?:[a-z]|\d(?!\d{0,2}(?:\.\d{1,3}){3}$))(?:[a-z0-9]|\.(?![\.\-])|\-(?![\.])){1,61}[a-z0-9]$/
    #  bucket_name = "media.kitmonsters.com"
    #  connection = Fog::Storage.new({
    #     :provider=>"AWS",
    #     :aws_secret_access_key=>"SECRET_ACCESS_KEY",
    #     :aws_access_key_id=>"ACCESS_KEY_ID"
    #  })
    # connection.put_object(bucket_name, "test.jpg", File.open("/Users/garry/Dropbox/Photos/360343585_acc8e25bfa_o.jpg"), {
    #   'x-amz-acl'=>"public-read",
    #   "Cache-Control"=> "max-age=315360000, public",
    #   "Expires"=>"Thu, 31 Dec 2037 23:55:55 GMT"
    # })
    # ===========================================================
    # bucket_name = 'uploadtest.magnetised.net'
    # bucket = storage.directories.get(bucket_name)
    # p bucket
    #
    # large = nil
    #
    # bm = Benchmark.measure do
    #   File.open('largefile.png', 'r') do |file|
    #     large = bucket.files.create(:key => 'largefile.png', :body => file, :idempotent => false, :public => true)
    #     # storage.put_object(bucket_name, 'largefile.png', file)
    #   end
    # end
    # puts "Took #{bm.real} seconds"
    # p storage.get_object_acl(bucket.key, large.key).body['AccessControlList']
    # p large.public_url
    #
    attr_reader :bucket_name

    # Don't verify my ssl certs when uploading images
    ::Excon.defaults[:ssl_verify_peer] = false

    def initialize(name, config, bucket_name, accepts = nil)
      super(name)
      @config, @bucket_name, @accepts = config, bucket_name, accepts
      if (host = @config.delete(:public_host))
        self.public_host = host
      end
      if (mapper = @config.delete(:url_mapper))
        self.url_mapper = mapper
      end
    end

    def open(relative_path, headers, mode, &block)
      Tempfile.open("spontaneous-cloud") do |tempfile|
        tempfile.binmode
        block.call(tempfile)
        tempfile.rewind
        self.copy(tempfile, relative_path, headers)
      end
    end

    def copy(existing_file, media_path, headers = {})
      params = {
        :key => join_path(media_path),
        :idempotent => false,
        :body => existing_file,
        :public => true,
        :cache_control => "max-age=#{1.year.to_i}, public",
      }.merge(headers)
      # Reopen file handles to catch updated contents
      src_path = existing_file.respond_to?(:read) ? existing_file.path : existing_file
      File.open(src_path, "rb") do |src|
        src.binmode
        params[:body] = src
        bucket.files.create(params)
      end
    end

    def join_path(path)
      path.join("/")
    end

    def local?
      false
    end

    def secure?
      @config[:secure]
    end

    def scheme
      secure? ? "https" : "http"
    end

    def backend
      @backend ||= Fog::Storage.new(@config)
    end

    def hostname
      config[:host] || bucket_public_url
    end

    def bucket
      @bucket ||= backend.directories.get(@bucket_name)
    end

    def url_path(path)
      "/" << join_path(path)
    end

    def default_url_mapper
      Proc.new { |path|
        if @config[:provider] == "AWS"
          aws_to_url(path)
        else
          bucket.files.new(key: path).public_url
        end
      }
    end

    # AWS Redirects to the bucketname.s3.amazonaws.com style of public URL
    # if you use the s3.amazonaws.com/bucketname/ style so to avoid a lot of
    # slow redirects when loading a page's media we use the fastest available
    # version
    def aws_to_url(path)
      if bucket_name =~ AWS_BUCKET_SUBDOMAIN_RESTRICTON_REGEX
        "https://#{bucket_name}.#{aws_s3_endpoint}#{path}"
      else
        "https://#{aws_s3_endpoint}/#{bucket_name}#{path}"
      end
    end

    def aws_s3_endpoint
      case (region = @config[:region])
      when nil, "", "us-east-1"
        "s3.amazonaws.com"
      else
        "s3-#{region}.amazonaws.com"
      end
    end

    def public_host=(host)
      @public_host = host
      unless host.blank?
        self.url_mapper = host_url_mapper(host)
      end
    end

    def host_url_mapper(host)
      uri = URI.parse(host)
      lambda { |path|
        return path if path.blank?
        begin
          path_uri = URI.parse(path)
          return path if path_uri.absolute?
          url = uri.clone
          url.path = path
          url.to_s
        rescue => e
          path
        end
      }
    end

    def root
     "/"
    end
  end
end
