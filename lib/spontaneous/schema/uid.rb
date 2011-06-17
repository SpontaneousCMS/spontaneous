# encoding: UTF-8


require 'base58'

module Spontaneous
  module Schema
    class UID
      @@instance_lock  = Mutex.new
      @@uid_lock  = Mutex.new
      @@uid_index = 0
      @@instances = {}

      extend Enumerable
      include Comparable

      def self.load(id, reference)
        @@instance_lock.synchronize do
          unless instance = @@instances[id]
            instance = self.new(id, reference)
            # check to make sure that the uid is valid first
            # this ensures that UIDs are not created before their owners
            # have uids
            if instance.valid?
              @@instances[id] = instance
            else
              instance = nil
            end
          end
          instance
        end
      end

      def self.create(reference)
        unless instance = @@instances.values.detect { |i| i.reference == reference }
          instance = self.load(generate(reference), reference)
        end
        instance
      end

      def existing_references
        @@instances.values.map { |i| i.reference }
      end

      def self.create_for(obj)
        create(obj.schema_name)
      end


      def self.clear!
        @@instances = {}
      end

      def self.[](id)
        return id if self === id
        return nil if id.blank?
        @@instances[id]
      end

      def self.each
        uids = @@instances.map { |id, instance| instance }
        if block_given?
          uids.each { |instance| yield(instance) }
        else
          uids.each
        end
      end

      def self.get_inc
        @@uid_lock.synchronize do
          @@uid_index = (@@uid_index + 1) % 0xFFFF
        end
      end

      def self.generate(ref = nil)
        generate58(ref)
      end

      def self.generate58(ref)
        # reverse the time so that sequential ids are more obviously different
        oid =  Base58.encode((Time.now.to_f * 1000).to_i).reverse
        oid << Base58.encode(get_inc).rjust(3, '0')
      end

      def self.generate16(ref)
        oid = ''
        # 4 bytes current time
        oid = (Time.now.to_f * 1000).to_i.to_s(16)
        # 2 bytes inc
        oid << get_inc.to_s(16).rjust(4, '0')
      end

      def self.to_hash
        Hash[ @@instances.map { |id, ref| [id, ref.reference] } ]
      end

      REFERENCE_SEP = "/".freeze

      attr_reader :reference, :name, :category

      def initialize(id, reference)
        @id = id.freeze
        @reference = reference
        @category, @owner_uid, @name = reference.split(REFERENCE_SEP)
        @category = @category.to_sym
      end

      class << self
        protected :new
      end

      def target
        @target ||= find_target
      end

      def valid?
        case @category
        when :type
          true
        else
          owner_uid
        end
      end

      def orphaned?
        target.nil?
      end

      def find_target
        case @category
        when :type
          begin
            @name.constantize
          rescue NameError => e
            nil
          end
        when :box
          owner.box_prototypes[name.to_sym]
        when :field
          owner.field_prototypes[name.to_sym]
        when :style
          owner.style_prototypes[name.to_sym]
        when :layout
          owner.layout_prototypes[name.to_sym]
        end
      end

      def owner
        owner_uid.target
      end

      def owner_uid
        self.class[@owner_uid]
      end

      def ==(obj)
        super or obj == @id
      end

      def hash
        @id.hash
      end

      def to_s
        @id
      end

      def <=>(other)
        self.to_s <=> other.to_s
      end

      def inspect
        %(#<#{self.class}:"#{@id}" => "#{reference}">)
      end
    end

  end
end
