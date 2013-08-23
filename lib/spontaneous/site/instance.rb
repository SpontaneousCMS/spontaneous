# encoding: UTF-8

class Spontaneous::Site
  module Instance
    extend Spontaneous::Concern

    module ClassMethods
      extend Forwardable

      # I can't make this instance thread-local because it acts as a central repository
      # of state & so must be shared between threads (e.g. within Puma)
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
