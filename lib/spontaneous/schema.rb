# encoding: UTF-8


require 'base58'

module Spontaneous
  module Schema
    # schema class <=> uid map backed by a file
    class PersistentMap
      attr_reader :map, :inverse_map

      def initialize(path)
        load_map(path)
        invert_map
      end

      def schema_id(obj)
        name_to_id(obj.schema_name)
      end

      def name_to_id(name)
        inverse_map[name]
      end

      def [](id)
        if uid = UID[id]
          uid.target
        else
          nil
        end
      end

      def load_map(path)
        UID.clear!
        if ::File.exists?(path)
          map = YAML.load_file(path)
          map.each do | uid, reference |
            UID.load(uid, reference)
          end
        end
      end

      def invert_map
        @inverse_map ||= generate_inverse
      end

      def generate_inverse
        Hash[ UID.map { |uid| [uid.reference, uid]} ]
      end

      def orphaned_ids
        UID.select { |uid| uid.target.nil? }
      end
    end

    # schema class <=> uid map with no backing, each run will generate different uids and
    # no schema validation errors will ever be thrown
    # used for tests
    class TransientMap < PersistentMap

      def initialize(path)
        UID.clear!
      end

      def schema_id(obj)
        if id = inverse_map[obj.schema_name]
          id
        else
          UID.load(Schema::UID.generate, obj.schema_name)
        end
      end

      def inverse_map
        generate_inverse
      end

      def orphaned_ids
        {}
      end
    end

    class << self
      def schema_loader_class
        @schema_loader_class ||= PersistentMap
      end

      def schema_loader_class=(klass)
        @schema_loader_class = klass
      end

      # validate the schema & attempt to fix anything that can be resolved without human
      # interaction (i.e. pure additions)
      def validate!
        validate_schema
      end

      # look for differences between identities found in schema map and
      # those defined in the schema classes and raise an error if any
      # are found
      def validate_schema
        @missing_from_map = Hash.new { |hash, key| hash[key] = [] }
        @missing_from_schema = []
        validate_classes
        unless @missing_from_map.empty? and @missing_from_schema.empty?
          modification = SchemaModification.new(@missing_from_map, @missing_from_schema)
          raise Spontaneous::SchemaModificationError.new(modification)
        end
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
      end

      def find_orphaned_ids
        map.orphaned_ids.each do |uid|
          @missing_from_schema << uid
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
      # only need this for the serialisation (which doesn't include boxes)
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
        Content.schema_reset!
        @classes = []
        @map = nil
      end

      def map
        @map ||= self.schema_loader_class.new(Spontaneous.schema_map)
      end

      def schema_id(obj)
        map.schema_id(obj)
      end

      def [](schema_id)
        map[schema_id]
      end
    end


    class UID
      @@instance_lock  = Mutex.new
      @@uid_lock  = Mutex.new
      @@uid_index = 0
      @@instances = {}

      extend Enumerable

      def self.load(id, reference)
        @@instance_lock.synchronize do
          unless instance = @@instances[id]
            @@instances[id] = instance = self.new(id, reference)
          end
          instance
        end
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
        @@instances.each { |id, instance| yield(instance) if block_given? }
      end

      def self.get_inc
        @@uid_lock.synchronize do
          @@uid_index = (@@uid_index + 1) % 0xFFFF
        end
      end

      def self.generate
        generate58
      end

      def self.generate58
        # reverse the time so that sequential ids are more obviously different
        oid =  Base58.encode((Time.now.to_f * 1000).to_i).reverse
        oid << Base58.encode(get_inc).rjust(3, '0')
      end

      def self.generate16
        oid = ''
        # 4 bytes current time
        oid = (Time.now.to_f * 1000).to_i.to_s(16)
        # 2 bytes inc
        oid << get_inc.to_s(16).rjust(4, '0')
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
        @owner ||= self.class[@owner_uid].target
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

      def inspect
        %(#<#{self.class}:"#{@id}" => "#{reference}">)
      end
    end

    class SchemaModification
      def initialize(missing_from_map, missing_from_schema)
        @missing_from_map = missing_from_map
        @missing_from_schema = missing_from_schema
      end

      def select_missing(select_type)
        @missing_from_schema.select do |reference|
          reference.category == select_type
        end
      end

      def added_classes
        @missing_from_map[:class].map { |m| m[0] }.uniq
      end

      def removed_classes
        select_missing(:type)
      end

      def added_fields
        @missing_from_map[:field].map { |m| m[1] }.uniq
      end

      def removed_fields
        select_missing(:field)
      end

      def added_boxes
        @missing_from_map[:box].map { |m| m[1] }.uniq
      end

      def removed_boxes
        select_missing(:box)
      end

      def added_styles
        @missing_from_map[:style].map { |m| m[1] }
      end

      def removed_styles
        select_missing(:style)
      end

      def added_layouts
        @missing_from_map[:layout].map { |m| m[1] }
      end

      def removed_layouts
        select_missing(:layout)
      end
    end
  end
end

