# encoding: UTF-8


require 'digest/md5'
require 'socket'

module Spontaneous
  module Schema
    class << self


      def validate!
        validate_schema
      end

      def validate_schema
        self.classes.each do | schema_class |
          schema_class.schema_validate
        end
      end


      def to_hash
        self.classes.inject({}) do |hash, klass|
          hash[klass.name] = klass.to_hash
          hash
        end
      end

      def to_json
        to_hash.to_json
      end

      def classes
        classes = []
        Content.subclasses.each do |klass|
          recurse_classes(klass, classes)
        end
        classes
      end

      def recurse_classes(root_class, list)
        root_class.subclasses.each do |klass|
          list << klass
          recurse_classes(klass, list)
        end
      end

      def reset!
        @map = nil
      end

      def schema_id(root, category = nil, name = nil)
        map.object_to_id(root, category, name)
      end

      def map
        @map ||= Map.new(Spontaneous.schema_map)
      end
    end

    class Map
      def initialize(path)
        @path = path
      end

      def object_to_id(root, category, name)
        uid, entry = root_entry(root)
        return nil unless uid
        if category and c = entry[category]
          uid, schema_name = c.detect do |i, n|
            n == name
          end
          uid
        else
          uid
        end
      end

      def root_entry(root_object)
        return nil unless map
        map.detect do |uid, entry|
          entry.name == root_object.schema_name
        end
      end

      def id_to_object(id)

      end

      def map
        @map ||= load_map
      end

      def load_map
        map = nil
        if ::File.exists?(@path)
          map = {}
          root = YAML.load_file(@path)
          root.each do |uid, entry|
            map[uid] = RootEntry.new(uid, entry)
          end
        end
        map
      end

      class RootEntry
        attr_reader :uid, :name

        def initialize(uid, entry)
          @uid = entry
          @name = entry[:name]
          @categories = entry[:categories]
        end

        def [](category)
          @categories[category]
        end

      end
    end
    class UID
      @@uid_lock  = Mutex.new
      @@uid_index = 0

      def self.get_inc
        @@uid_lock.synchronize do
          @@uid_index = (@@uid_index + 1) % 0xFFFFFF
        end
      end

      def self.generate
        oid = ''
        # 4 bytes current time
        time = Time.new.to_i
        oid += [time].pack("N")
        # 2 bytes inc
        oid += [get_inc].pack("N")[2, 3]

        data = oid.unpack("C6")
        str = ' ' * 12
        6.times do |i|
          str[i * 2, 2] = '%02x' % data[i]
        end
        self.new(str)
      end

      def initialize(uid)
        @uid = uid
      end

      def eql?(o)
        o.to_s == @uid
      end
      alias_method :==, :eql?

      def to_s
        @uid
      end
    end
  end
end
