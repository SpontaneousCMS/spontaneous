# encoding: UTF-8

module Spontaneous::Media
  module Store
    autoload :Backend, "spontaneous/media/store/backend"
    autoload :Local,   "spontaneous/media/store/local"
    autoload :Cloud,   "spontaneous/media/store/cloud"

    extend self

    def create(name, config)
      case config[:provider]
      when "Local", "local"
        Local.new(name, config[:local_root], config[:url], config[:accepts])
      else
        bucket =  config.delete(:bucket)
        accepts = config.delete(:accepts)
        Cloud.new(name, config, bucket, accepts)
      end
    end
  end
end
