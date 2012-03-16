module Spontaneous::Plugins::Site
  module URL
    extend ActiveSupport::Concern

    module ClassMethods
      def public_url(path = "/")
        instance.public_url(path)
      end
    end

    def public_url(path = "/")
      "http://%s%s" % [ config.site_domain, path ]
    end
  end
end
