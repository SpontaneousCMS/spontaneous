class Spontaneous::Site
  module URL
    extend Spontaneous::Concern

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
