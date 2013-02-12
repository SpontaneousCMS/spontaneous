# encoding: UTF-8

class Spontaneous::Site
  module Instance
    extend Spontaneous::Concern

    module ClassMethods
      extend Forwardable

      def instantiate(root, env, mode)
        Thread.current[:spontaneous_site_instance] = Spontaneous::Site.new(root, env, mode)
      end

      def instance
        Thread.current[:spontaneous_site_instance]
      end

      def_delegators :instance, :config, :database, :database=
    end # ClassMethods
  end # Instance
end
