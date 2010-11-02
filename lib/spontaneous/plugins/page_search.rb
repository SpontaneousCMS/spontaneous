# encoding: UTF-8

module Spontaneous::Plugins
  module PageSearch
    module ClassMethods
      def root
        Spontaneous::Content.first(:path => Spontaneous::SLASH)
      end

      def path(path)
        Spontaneous::Content.first(:path => path)
      end

      def uid(uid)
        Spontaneous::Content.first(:uid => uid)
      end
    end

    # module InstanceMethods
    # end
  end
end

