# encoding: UTF-8


require 'digest/md5'
require 'socket'

module Spontaneous
  module Schema
    class << self

      attr_accessor :missing_classes

      def validate!
        @missing_from_map = Hash.new { |hash, key| hash[key] = [] }
        @missing_from_schema = Hash.new { |hash, key| hash[key] = [] }
        validate_schema
        unless @missing_from_map.empty? and @missing_from_schema.empty?
          raise Spontaneous::SchemaModificationError.new(@missing_from_map, @missing_from_schema)
        end
      end

      def validate_schema
        # will check that each of the classes in the schema has a
        # corresponding id
        self.content_classes.each do | schema_class |
          schema_class.schema_validate
        end
        # now check that each of the ids in the map has a
        # corresponding entry in the schema

        names = self.content_classes.map { |c| c.name }
        not_found = []
        map.each do |id, entry|
          not_found << entry unless names.include?(entry.name)
        end

        not_found.each do |entry|
          @missing_from_schema[:class] << [entry.name, nil]
        end
      end

      def missing_id!(klass, category=:class, name=nil)
        @missing_from_map[category] << [klass, name]
      end


      def to_hash
        self.content_classes.inject({}) do |hash, klass|
          hash[klass.name] = klass.to_hash
          hash
        end
      end

      def to_json
        to_hash.to_json
      end

      # all classes including boxes
      def classes
        @classes ||= []
      end

      # just subclasses of Content (excluding boxes)
      def content_classes
        classes = []
        Content.subclasses.each do |klass|
          classes << klass unless [Spontaneous::Page, Spontaneous::Piece].include?(klass)
          recurse_classes(klass, classes)
        end
        classes.uniq
      end

      def recurse_classes(root_class, list)
        root_class.subclasses.each do |klass|
          list << klass unless list.include?(klass)
          recurse_classes(klass, list)
        end
      end

      def reset!
        @classes = []
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
      include Enumerable

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
        mapping.detect do |uid, entry|
          entry.name == root_object.schema_name
        end
      end

      def id_to_object(id)

      end

      def mapping
        @mapping ||= load_mapping
      end

      def each
        mapping.each { |e| yield e if block_given? }
      end

      def load_mapping
        map = {}
        if ::File.exists?(@path)
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
