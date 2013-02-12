# encoding: UTF-8

require 'fog'
require 'tempfile'

module Spontaneous::Storage
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

    def initialize(config, bucket_name, accepts = nil)
      @config, @bucket_name, @accepts = config, bucket_name, accepts
      @public_host = @config.delete(:public_host)
    end

    def open(relative_path, mimetype, mode, &block)
      Tempfile.open("spontaneous-cloud") do |tempfile|
        tempfile.binmode
        block.call(tempfile)
        tempfile.rewind
        self.copy(tempfile, relative_path, mimetype)
      end
    end

    def copy(existing_file, media_path, mimetype)
      params = {
        :key => join_path(media_path),
        :idempotent => false,
        :body => existing_file,
        :public => true,
        :expires => (DateTime.now + 20.years).to_s(:rfc822),
        :content_type => mimetype
      }
      params[:body] = File.open(existing_file) if existing_file.is_a?(String)
      bucket.files.create(params)
    end

    def join_path(path)
      path.join("-")
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

    def public_url(path)
      if @public_host
        "#{@public_host}/#{join_path(path)}"
      else
        if @config[:provider] == "AWS"
          public_url_aws(path)
        else
          bucket.files.new(:key => join_path(path)).public_url
        end
      end
    end

    # AWS Redirects to the bucketname.s3.amazonaws.com style of public URL
    # if you use the s3.amazonaws.com/bucketname/ style so to avoid a lot of
    # slow redirects when loading a page's media we use the fastest available
    # version
    def public_url_aws(path)
      if bucket_name =~ AWS_BUCKET_SUBDOMAIN_RESTRICTON_REGEX
        "https://#{bucket_name}.s3.amazonaws.com/#{join_path(path)}"
      else
        "https://s3.amazonaws.com/#{bucket_name}/#{join_path(path)}"
      end
    end

    def root
     "/"
    end
  end
end
