# encoding: UTF-8



module Spontaneous
  module Schema
    autoload :UID, 'spontaneous/schema/uid'
    autoload :SchemaModification, 'spontaneous/schema/schema_modification'
    # schema class <=> uid map backed by a file
    class PersistentMap
      attr_reader :map, :inverse_map

      def initialize(path)
        @path = path
        load_map
      end

      def schema_id(obj)
        reference_to_id(obj.schema_name)
      end

      def reference_to_id(reference)
        UID.get_id(reference)
      end

      def [](id)
        if uid = UID[id]
          uid.target
        else
          nil
        end
      end

      def load_map
        if exists?
          map = YAML.load_file(@path)
          map.each do | uid, reference |
            UID.load(uid, reference)
          end
        end
      end

      def exists?
        ::File.exists?(@path)
      end

      # def invert_map
      #   @inverse_map = generate_inverse
      # end

      # def generate_inverse
      #   Hash[ UID.map { |uid| [uid.reference, uid]} ]
      # end

      def orphaned_ids
        UID.select { |uid| uid.orphaned? }
      end

      def reload!
        # invert_map
      end
    end

    # schema class <=> uid map with no backing, each run will generate different uids and
    # no schema validation errors will ever be thrown
    # used for tests
    class TransientMap < PersistentMap

      def initialize(path)
      end

      def schema_id(obj)
        if id = super
          id
        else
          UID.create(obj.schema_name)
        end
      end

      def orphaned_ids
        []
      end

      def exists?
        true
      end
    end

    class << self
      def schema_loader_class
        @schema_loader_class ||= PersistentMap
      end

      def schema_loader_class=(klass)
        UID.clear!
        @map = nil
        @schema_loader_class = klass
      end

      # validate the schema & attempt to fix anything that can be resolved without human
      # interaction (i.e. pure additions)
      def validate!
        begin
          validate_schema
        rescue Spontaneous::SchemaModificationError => e
          changes = e.modification
          # if the map file is missing, then this is a first run and we can just
          # create the thing by populating it with the current schema
          if !map.exists?
            generate_new_schema
          else
            if changes.resolvable?
              while changes and changes.resolvable? do
                changes.resolve!
                map.reload!
                changes = perform_validation
              end
              write_schema(Spontaneous.schema_map)
              reload!
            else
              raise e
            end
          end
        end
      end

      def apply_fix(action)
        case action.action
        when :delete
          uid = action.source
          uid.destroy
        when :rename
          uid = action.source
          dest = action.dest
          uid.rewrite!(action.dest)
        end
        write_schema(Spontaneous.schema_map)
        reload!
      end

      def generate_new_schema
        logger.info("Generating new schema map at #{Spontaneous.schema_map}")
        self.schema_loader_class = TransientMap
        classes.each do | schema_class |
          generate_schema_for(schema_class)
        end
        write_schema(Spontaneous.schema_map)
        self.schema_loader_class = PersistentMap
      end

      def write_schema(path)
        File.open(path, 'w') do |file|
          file.write(UID.to_hash.to_yaml)
        end
      end

      def generate_schema_for(obj)
        UID.create_for(obj)
        [:boxes, :fields, :styles, :layouts].each do |category|
          if obj.respond_to?(category)
            objects = obj.send(category)
            objects.each do | c |
              generate_schema_for(c)
            end
          end
        end
      end

      # look for differences between identities found in schema map and
      # those defined in the schema classes and raise an error if any
      # are found
      def validate_schema
        modification = perform_validation
        unless modification.nil?
          raise Spontaneous::SchemaModificationError.new(modification)
        end
      end

      def perform_validation
        modification = nil
        @missing_from_map = Hash.new { |hash, key| hash[key] = [] }
        @missing_from_schema = []
        validate_classes

        unless @missing_from_map.empty? and @missing_from_schema.empty?
          modification = SchemaModification.new(@missing_from_map, @missing_from_schema)
        end
        modification
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

      def missing_id!(category, obj)
        @missing_from_map[category] << obj
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

      # should only be used in tests
      def reset!
        Content.schema_reset!
        @classes = []
        reload!
      end

      def reload!
        @map = nil
        UID.clear!
      end

      def schema_map_file
        @schema_map_file ||= Spontaneous.root / "config" / "schema.yml"
      end

      def schema_map_file=(path)
        # force a reloading of the schema map
        @map = nil
        @schema_map_file = path
      end

      def map
        @map ||= self.schema_loader_class.new(schema_map_file)
      end

      def schema_id(obj)
        map.schema_id(obj)
      end

      def [](schema_id)
        map[schema_id]
      end
    end
  end
end

