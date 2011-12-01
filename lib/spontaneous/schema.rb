# encoding: UTF-8



module Spontaneous
  module Schema
    autoload :UID, 'spontaneous/schema/uid'
    autoload :UIDMap, 'spontaneous/schema/uid_map'
    autoload :SchemaModification, 'spontaneous/schema/schema_modification'
    # schema class <=> uid map backed by a file
    class PersistentMap
      attr_reader :map, :inverse_map, :uids

      def initialize(uids, path)
        @uids, @path = uids, path
        load_map
      end

      def schema_id(obj)
        reference_to_id(obj.schema_name)
      end

      def reference_to_id(reference)
        uids.get_id(reference)
      end

      def [](id)
        if uid = uids[id]
          uid.target
        else
          nil
        end
      end

      def load_map
        if exists?
          map = YAML.load_file(@path)
          map.each do | uid, reference |
            uids.load(uid, reference)
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
        uids.select { |uid| uid.orphaned? }
      end

      def reload!
        # invert_map
      end
    end

    # schema class <=> uid map with no backing, each run will generate different uids and
    # no schema validation errors will ever be thrown
    # used for tests
    class TransientMap < PersistentMap

      def initialize(uids, path)
        @uids = uids
      end

      def schema_id(obj)
        if id = super
          id
        else
          uids.create(obj.schema_name)
        end
      end

      def orphaned_ids
        []
      end

      def exists?
        true
      end
    end

    class Schema
      attr_reader :schema_loader_class, :uids

      def initialize(root, schema_loader_class = Spontaneous::Schema::PersistentMap)
        @root = root
        @schema_loader_class = schema_loader_class
        initialize_uid_map
      end

      def schema_loader_class=(klass)
        initialize_uid_map
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
            logger.warn("Generating new schema")
            generate_new_schema
          else
            if changes.resolvable?
              logger.warn("Schema changed...")
              attempts = 0
              while changes and changes.resolvable? do
                logger.warn("Fixing automatically")
                changes.resolve!
                map.reload!
                changes = perform_validation
                raise "Infinite loop in schema resolution" if (attempts += 1) >= 5
              end
              write_schema
              reload!
            else
              logger.warn("Unable to resolve schema changes")
              raise e
            end
          end
        end
      end

      def apply(action)
        apply_fix(action.action, action.source, action.dest)
      end

      def apply_fix(action, source, dest=nil)
        uid = uids[source]
        case action
        when :delete
          uids.destroy(uid)
        when :rename
          uid.rewrite!(dest)
        end
        write_schema
        reload!
        validate!
        logger.info("✓ Schema updated successfully")
      end

      def generate_new_schema
        logger.info("Generating new schema map at #{schema_map_file}")
        self.schema_loader_class = TransientMap
        classes.each do | schema_class |
          generate_schema_for(schema_class)
        end
        write_schema
        self.schema_loader_class = PersistentMap
      end

      def write_schema
        File.atomic_write(schema_map_file) do |file|
          file.write(uids.export.to_yaml)
        end
      end

      def generate_schema_for(obj)
        uids.create_for(obj)
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


      def export
        self.content_classes.inject({}) do |hash, klass|
          hash[klass.name] = klass.export
          hash
        end
      end

      def serialise_http(user = nil)
        Spontaneous.serialise_http(export)
      end

      # all classes including boxes
      def classes
        @classes ||= []
      end

      def add_class(supertype, type)
        inheritance_map[supertype.to_s] << type
        classes << type unless classes.include?(type)
      end

      def inheritance_map
        @inheritance_map ||= Hash.new { |h, k| h[k] = [] }
      end


      def subclasses_of(type)
        inheritance_map[type.to_s].map { |subclass| subclass }
      end

      def descendents_of(type)
        subclasses_of(type).map{ |x| [x] + descendents_of(x) }.flatten
      end

      # just subclasses of Content (excluding boxes)
      # only need this for the serialisation (which doesn't include boxes)
      def content_classes
        classes = []
        self.classes.reject { |k| k.is_box? }.each do |klass|
          classes << klass unless [Spontaneous::Page, Spontaneous::Piece].include?(klass)
          # recurse_classes(klass, classes)
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
        @inheritance_map = nil
        reload!
      end

      def reload!
        @map = nil
        initialize_uid_map
      end

      def initialize_uid_map
        @uids = Spontaneous::Schema::UIDMap.new
      end

      def delete(klass)
        classes.delete(klass)
      end

      def schema_map_file
        @schema_map_file ||= @root / "config" / "schema.yml"
      end

      def schema_map_file=(path)
        # force a reloading of the schema map
        @map = nil
        @schema_map_file = path
      end

      def map
        @map ||= self.schema_loader_class.new(@uids, schema_map_file)
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

