# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Instance
    extend ActiveSupport::Concern

    module ClassMethods
      extend Forwardable

      @@instance = nil

      def instantiate(root, env, mode)
        @@instance = Spontaneous::Site.new(root, env, mode)
      end

      def instance
        @@instance
      end

      def_delegators :instance, :config, :database, :database=
    end # ClassMethods
  end # Instance
end
