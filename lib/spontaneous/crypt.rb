# encoding: UTF-8

module Spontaneous
  module Crypt
    VERSION_SEP = "%".freeze

    module ModuleMethods
      def current
        return version(@forced) if @forced
        versions.last
      end

      def force_version(n)
        @forced = n
      end

      def default_version
        @forced = nil
      end

      def versions
        Version.subclasses.sort { |v1, v2| v1.version <=> v2.version }
      end

      def hash(password)
        current.create(password)
      end

      def version(version)
        versions.detect { |v| v.version == version }
      end

      def valid?(password, blob)
        new(password, blob).valid?
      end

      def serialize(version, hash)
        [version, hash].join VERSION_SEP
      end

      def version_split(blob)
        version, hash = blob.split(VERSION_SEP)
        [version.to_i, hash]
      end

      def outdated?(version)
        version.version < current.version
      end

      def new(password, blob)
        version, hash = version_split(blob)
        Validator.new(password, Crypt.version(version).new(hash))
      end
    end

    extend ModuleMethods

    class Validator
      def initialize(password, version)
        @password, @version = password, version
      end

      def valid?
        @version.valid?(@password)
      end

      def outdated?
        @version.outdated?
      end

      alias_method :needs_upgrade?, :outdated?

      def upgrade
        Spontaneous::Crypt.hash(@password)
      end

      def salt
        @version.salt
      end
    end
  end
end

require 'spontaneous/crypt/version'
