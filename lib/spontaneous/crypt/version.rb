require 'bcrypt'

module Spontaneous::Crypt
  class Version
    FIELD_SEP   = ":".freeze

    module ClassMethods
      def subclasses
        @subclasses ||= []
      end

      def inherited(subclass)
        subclasses << subclass
        super
      end

      def version(*args)
        return @version if args.empty?
        @version = args.first
      end

      def serialize(hash)
        Spontaneous::Crypt.serialize(version, hash)
      end

      def valid?(password, hash)
        self.new(hash).valid?(password)
      end
    end

    extend ClassMethods

    def initialize(hash)
      @hash = hash
    end

    def valid?(password)
      # Depends on implementation
    end

    def outdated?
      Spontaneous::Crypt.outdated?(self.class)
    end

    def salt
      # Depends on implementation
    end

    # A fast version for use during testing
    class Fake < Version
      version 0

      def self.create(password)
        serialize generate(password)
      end

      def self.generate(password)
        Digest::SHA1.hexdigest(password)
      end

      def valid?(password)
        @hash == self.class.generate(password)
      end

      def outdated?
        false
      end

      def salt
        ""
      end
    end
    class SHALegacy < Version
      version 201102

      def self.create(hash, salt)
        serialize [salt, BCrypt201301.generate(hash)].join(FIELD_SEP)
      end

      def self.sha(salt, password)
        Digest::SHA1.hexdigest("--#{salt}--#{password}--")
      end

      def initialize(blob)
        @salt, hash = blob.split(FIELD_SEP)
        @bcrypt = BCrypt201301.new(hash)
      end

      def valid?(password)
        @bcrypt.valid?(sha(password))
      end

      def sha(password)
        self.class.sha(@salt, password)
      end

      def salt
        @salt
      end
    end

    class BCrypt201301 < Version
      version 201301

      def self.cost
        13
      end

      def self.create(password)
        serialize generate(password)
      end

      def self.generate(password)
        ::BCrypt::Password.create(password, :cost => cost)
      end

      def valid?(password)
        self.password == password
      end

      def password
        @password ||= ::BCrypt::Password.new(@hash)
      end

      def salt
        password.salt
      end
    end
  end
end
