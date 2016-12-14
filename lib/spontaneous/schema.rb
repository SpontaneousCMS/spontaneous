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

      def to_id(obj)
        reference_to_id(obj.schema_name)
      end

      def reference_to_id(reference)
        uids.get_id(reference)
      end

      def to_class(id)
        if uid = uids[id]
          uid.target
        else
          nil
        end
      end

      def box_ids
        category_ids(:box)
      end

      def category_ids(category)
        uids.select { |uid| uid.category == category }
      end

      def load_map
        if exists? && (map = parse_map)
          map.each do | uid, reference |
            uids.load(uid, reference)
          end
        end
      end

      def parse_map
        YAML.load_file(@path)
      end

      def exists?
        ::File.exists?(@path)
      end

      def valid?
        exists? && parse_map.is_a?(Hash)
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

      def to_id(obj)
        if id = super
          id
        else
          uids.create(obj.schema_name)
        end
      end

      def box_ids
        []
      end

      def orphaned_ids
        []
      end

      def exists?
        true
      end

      def valid?
        true
      end
    end

    def self.new(site, root, schema_loader_class = Spontaneous::Schema::PersistentMap)
      Schema.new(site, root, schema_loader_class)
    end

    def self.schema_name(type, parent, name)
      [type, parent, encode_schema_name(name)].join(Spontaneous::SLASH)
    end

    def self.transform_maintaining_type(name)
      return name if name.blank?
      transformed = yield(name.to_s)
      return transformed.to_sym if Symbol === name
      transformed
    end

    def self.encode_schema_name(name)
      transform_maintaining_type(name) { |s| s.gsub(/\//, '%2F') }
    end

    def self.decode_schema_name(name)
      transform_maintaining_type(name) { |s| s.gsub(/%2F/, '/') }
    end

    class Schema
      attr_accessor :schema_loader_class
      attr_reader   :uids
      attr_reader   :site

      def initialize(site, root, schema_loader_class = Spontaneous::Schema::PersistentMap)
        @site, @root = site, root
        @schema_loader_class = schema_loader_class
        @subclass_map = Hash.new { |h, k| h[k] = [] }
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

          if !map.valid?
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
          after_delete(uid)
        when :rename
          uid.rewrite!(dest)
        end
        write_schema
        reload!
        validate!
        logger.info("✓ Schema updated successfully")
      end

      # now I want to clean up the content, removing any types associated with UIDs
      # that no longer exist and then cleaning up after that by looking for any
      # instances with an invalid content path. This can happen because when a
      # type is removed it becomes difficult to instantiate any entries that remain
      # in the db
      def after_delete(uid)
        result = Spontaneous::Model::Action::Clean.run(@site)
        logger.warn("Deleted #{result[:invalid]} invalid and #{result[:orphans]} orphaned content instances.")
        logger.warn("Site must_publish_all flag has been set") if result[:publish]
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
          schema_class.schema_validate(self)
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


      def export(user = nil)
        self.content_classes.inject({}) do |hash, klass|
          hash[klass.ui_class] = klass.export(user)
          hash
        end
      end

      def serialise_http(user = nil)
        Spontaneous.serialise_http(export(user))
      end

      def unfiltered_classes
        @classes ||= []
      end

      # all classes including boxes
      def classes
        unfiltered_classes.reject { |c| is_excluded_type?(c) }
      end

      def inherited(supertype, type)
        inheritance_map[supertype.to_s] << type
        unfiltered_classes << type
      end

      def is_excluded_type?(type)
        excluded_types.include?(type)
      end

      def excluded_types
        model = @site.model
        [model, model::Page, model::Piece]
      end

      def inheritance_map
        @inheritance_map ||= empty_inheritance_map
      end

      def empty_inheritance_map
        Hash.new { |h, k| h[k] = [] }
      end

      def subclasses_of(type)
        inheritance_map[type.to_s].map { |subclass| subclass }
      end

      def descendents_of(type)
        subclasses_of(type).flat_map{ |x| [x] + descendents_of(x) }
      end

      alias_method :subclasses, :descendents_of

      # just subclasses of Content (excluding boxes)
      # only need this for the serialisation (which doesn't include boxes)
      #
      # TODO: Find a way to filter out the top-level classes without hard-coding
      # them here.
      def content_classes
        classes.select { |k| k.is_a?(Spontaneous::DataMapper::ContentModel) }.uniq
      end

      def types
        content_classes
      end

      def recurse_classes(root_class, list)
        root_class.subclasses.each do |klass|
          list << klass unless list.include?(klass)
          recurse_classes(klass, list)
        end
      end

      def reset!
        @classes         = []
        @types           = []
        @inheritance_map = nil
        reload!
      end

      def reload!
        @map = nil
        initialize_uid_map
      end

      def initialize_uid_map
        @uids = Spontaneous::Schema::UIDMap.new(@site)
      end

      # It's obvious from this method that schema classes are
      # stored in too many ways
      def delete(klass)
        constants_of(klass).each { |const| delete(const) }
        unfiltered_classes.delete(klass)
        remove_group_members(klass)
        inheritance_map.delete(klass.to_s)
        inheritance_map.each do |supertype, subtypes|
          subtypes.delete(klass)
        end
      end

      def constants_of(klass)
        return [] unless klass.respond_to?(:constants)
        return [] if klass == ::BasicObject
        klass.constants.
          select { |c| klass.const_defined?(c, false) }.
          map { |c| klass.const_get(c) }
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

      def to_id(obj)
        map.to_id(obj)
      end

      def to_class(id)
        map.to_class(id)
      end

      def groups
        @groups ||= Hash.new { |h, k| h[k] = [] }
      end

      def box_ids
        map.box_ids
      end

      def add_group_member(schema_class, group_names)
        group_names.each do |name|
          group = groups[name.to_sym]
          group << schema_class.to_s unless group.include?(schema_class.to_s)
        end
      end

      def is_group?(group_name)
        groups.key?(group_name.to_sym)
      end

      def group_memberships(klass)
        classname = klass.to_s
        groups.select { |group, members| members.include?(classname) }.keys
      end

      def remove_group_members(klass)
        type = klass.to_s
        groups.each do |group, members|
          members.delete(type)
        end
      end

      def inspect
        %(#<#{self.class} root="#{@root}">)
      end
    end
  end
end

