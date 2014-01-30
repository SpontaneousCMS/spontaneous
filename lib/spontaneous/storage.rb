# encoding: UTF-8

module Spontaneous
  module Storage
    autoload :Backend, "spontaneous/storage/backend"
    autoload :Local,   "spontaneous/storage/local"
    autoload :Cloud,   "spontaneous/storage/cloud"

    extend self

    def create(config)
      case config[:provider]
      when "Local", "local"
        Spontaneous::Storage::Local.new(config[:local_root], config[:url], config[:accepts])
      else
        bucket =  config.delete(:bucket)
        accepts = config.delete(:accepts)
        Spontaneous::Storage::Cloud.new(config, bucket, accepts)
      end
    end
  end
end
