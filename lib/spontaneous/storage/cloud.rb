# encoding: UTF-8

require 'fog'

module Spontaneous::Storage
  class Cloud < Backend
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
  end
end
