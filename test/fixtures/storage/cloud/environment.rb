test_setting true

storage :s3 do |config|
  config.update({
    :provider => "AWS",
    :aws_access_key_id => "ACCESS_KEY_ID",
    :aws_secret_access_key => "SECRET_ACCESS_KEY",
    :bucket => "media.example.com",
    :endpoint => "http://media.example.com",
    :host => "media.example.com"
  })
end
