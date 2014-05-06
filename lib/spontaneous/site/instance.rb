# encoding: UTF-8

class Spontaneous::Site
  module Instance
    extend Spontaneous::Concern

    module ClassMethods
      extend Forwardable

      def instantiate(root, env, mode)
        @__instance__ = Spontaneous::Site.new(root, env, mode)
      end

      def instance
        @__instance__
      end

      def_delegators :instance, :config, :database, :database=
    end # ClassMethods
  end # Instance
end
