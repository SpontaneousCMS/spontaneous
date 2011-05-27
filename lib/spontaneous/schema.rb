# encoding: UTF-8


require 'digest/md5'
require 'socket'

module Spontaneous
  module Schema
    class << self

      attr_accessor :missing_classes

      def validate!
        @missing_from_map = Hash.new { |hash, key| hash[key] = [] }
        @missing_from_schema = []
        validate_schema
        unless @missing_from_map.empty? and @missing_from_schema.empty?
          modification = SchemaModification.new(@missing_from_map, @missing_from_schema)
          raise Spontaneous::SchemaModificationError.new(modification)
        end
      end

      def validate_schema
        validate_classes
      end

      def validate_classes
        # will check that each of the classes in the schema has a
        # corresponding id
        self.classes.each do | schema_class |
          schema_class.schema_validate
        end
        # now check that each of the ids in the map has a
        # corresponding entry in the schema

        find_orphaned_ids
        # find_orphaned_field_ids
      end

      def all_defined_ids
        ids = {}
        classes.each do | schema_class |
          ids[schema_class.schema_id] = schema_class
          [:fields, :boxes, :styles, :layouts].each do |category|
            if schema_class.respond_to?(category)
              schema_class.send(category).each { |o| ids[o.schema_id] = o }
            end
          end
        end
        ids
      end

      def find_orphaned_ids
        ids = all_defined_ids.keys
        map = self.map.dup
        ids.each { |id| map.delete(id) }
        map.each do |id, name|
          @missing_from_schema << name
        end
      end

      def find_orphaned_class_ids
        names = self.classes.map { |c| c.schema_name }
        not_found = []
        map.each do |id, entry|
          not_found << entry unless names.include?(entry)
        end
        not_found.each do |entry|
          @missing_from_schema[:class] << [entry, nil]
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
        @map = @inverse_map = nil
      end

      def find(id)
        all_defined_ids[id]
      end

      def schema_id(obj)
        name_to_id(obj.schema_name)
      end

      def id_to_name(id)
        map[id]
      end

      def name_to_id(name)
        inverse_map[name]
      end

      def map
        @map ||= load_map
      end

      def inverse_map
        @inverse_map ||= map.invert
      end

      def load_map
        map = {}
        if ::File.exists?(Spontaneous.schema_map)
          map = YAML.load_file(Spontaneous.schema_map)
        end
        map
      end
    end

    class SchemaModification
      def initialize(missing_from_map, missing_from_schema)
        @missing_from_map = missing_from_map
        @missing_from_schema = missing_from_schema
      end

      def select_missing(select_type)
        @missing_from_schema.map do |name|
          name.split('/')
        end.select do |type, owner, name|
          type == select_type
        end.map do |type, owner, name|
          [owner, name]
        end
      end

      def added_classes
        @missing_from_map[:class].map { |m| m[0] }
      end

      def removed_classes
        select_missing('type').map { |owner, name| name }
      end

      def added_fields
        @missing_from_map[:field].map { |m| m[1] }
      end

      def removed_fields
        select_missing('field').map { |owner, name| MissingField.new(owner, name) }
      end

      def added_boxes
        @missing_from_map[:box].map { |m| m[1] }
      end

      def removed_boxes
        select_missing('box').map { |owner, name| MissingBox.new(owner, name) }
      end

      def added_styles
        @missing_from_map[:style].map { |m| m[1] }
      end

      def removed_styles
        select_missing('style').map { |owner, name| MissingStyle.new(owner, name) }
      end

      def added_layouts
        @missing_from_map[:layout].map { |m| m[1] }
      end

      def removed_layouts
        select_missing('layout').map { |owner, name| MissingLayout.new(owner, name) }
      end

      def self.Missing(category)
        Class.new do
          class_eval (<<-RUBY)
            attr_reader :owner, :name
            attr_accessor :category

            def initialize(owner_id, name)
              @owner = Spontaneous::Schema.find(owner_id)
              @name = name
            end

            def category
              :#{category}
            end
          RUBY
        end
      end

      MissingType = Missing(:type)
      MissingBox = Missing(:box)
      MissingField = Missing(:field)
      MissingStyle = Missing(:style)
      MissingLayout = Missing(:layout)
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
