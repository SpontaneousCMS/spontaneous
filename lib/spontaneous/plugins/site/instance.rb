# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Instance
    module ClassMethods
      extend Forwardable

      def instantiate(root, env, mode)
        @instance = self.new(root, env, mode)
      end

      def instance
        @instance
      end

      def_delegators :instance, :config, :database, :database=
    end # ClassMethods
  end # Map
end

