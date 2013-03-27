# encoding: UTF-8

module Spontaneous::Publishing
  class Revision
    class InvalidRevision < Spontaneous::Error; end

    class Generator
      # Both revision & source_revision should be instances of Revision
      def initialize(revision)
        @revision = revision
      end

      def run
        @revision.transaction do
          create
        end
      end

      def create
        begin
          create_revision
          copy_indexes
          sync_revision
          set_revision_timestamps
          set_revision_version
          @revision.complete
          @revision.scope do
            yield if block_given?
          end
          set_source_timestamps
        rescue => e
          @revision.delete
          raise e
        end
      end

      protected

      def create_revision
        db.run(<<-SQL)
          CREATE TABLE #{db.literal(@revision.table)}
            AS #{source_dataset.select_sql}
        SQL
      end

      def source_dataset
        @revision.content_dataset
      end

      def copy_indexes
        indexes = db.indexes(@revision.content_table)
        indexes.each do |name, options|
          columns = options.delete(:columns)
          db.add_index(@revision.table, columns, options)
        end
      end

      def sync_revision
        # To be overwritten in Patch subclass
      end

      def set_revision_timestamps
        set_timestamps(@revision.dataset)
      end

      # Update the timestamps on the :content table
      #
      # Only do this once we're sure the
      # publish has completed successfully as they are used
      # to track which pages need publishing
      def set_source_timestamps
        set_timestamps(@revision.content_dataset)
      end

      def set_timestamps(ds)
        published_dataset(ds).update({
          :last_published_at => Sequel.datetime_class.now
        })
        first_published_dataset(ds).update({
          :first_published_at => Sequel.datetime_class.now,
          :first_published_revision => revision
        })
      end

      def published_dataset(ds)
        ds
      end

      def first_published_dataset(ds)
        ds.filter(:first_published_at => nil)
      end

      def set_revision_version
        @revision.dataset.update(:revision => revision)
      end

      def mapper
        @revision.mapper
      end

      def db
        @revision.db
      end

      def revision
        @revision.revision
      end
    end

    class Patcher < Generator
      def initialize(revision, modified)
        super(revision)
        # pages should be published in depth order because it's
        # possible to be publishing a child of
        # a page that's never been published
        @modified = modified.sort { |m1, m2| m1.depth <=> m2.depth }
      end

      def source_dataset
        @revision.previous.history_dataset
      end

      def sync_revision
        @modified.each do |m|
          m.sync_to_revision(revision, true)
        end
      end

      def published_dataset(ds)
        filter_ids(super)
      end

      def first_published_dataset(ds)
        filter_ids(super)
      end

      def filter_ids(ds)
        ds.filter(:id => @modified.map(&:id))
      end
    end

    def self.create(model, revision, &block)
      new(model, revision).create(&block)
    end

    def self.patch(model, revision, modified, &block)
      new(model, revision).patch(modified, &block)
    end

    def self.exists?(model, revision)
      new(model, revision).table_exists?
    end

    def self.delete(model, revision)
      return if revision.nil?
      new(model, revision).delete
    end

    def self.delete_all(model)
      revisions = tables(model).map { |table| for_table(model, table) }

      # Don't call the full Revision#delete because it is much more efficient
      # to delete the contents of the revision tables in a single
      # command rather than revision by revision
      revisions.each(&:delete_table)
      history_dataset(model).delete
      archive_dataset(model).delete
    end

    def self.cleanup(model, current_revision, keep_revisions)
      current = table(model, current_revision)
      tables = tables(model).reject { |t| t == current }
      tables.each do |table|
        model.database.drop_table(table)
      end
      history_dataset(model) { revision <= (current_revision - keep_revisions) }.delete
    end

    def self.history_dataset(model, revision = nil, &block)
      _filter_dataset(model.mapper.revision_history_dataset, revision, &block)
    end

    def self.archive_dataset(model, revision = nil, &block)
      _filter_dataset(model.mapper.revision_archive_dataset, revision, &block)
    end

    def self._filter_dataset(ds, revision, &block)
      return ds.filter(&block) if revision.nil?
      ds.filter(:revision => revision, &block)
    end

    def self.for_table(model, table)
      r = revision_from_table(model, table)
      new(model, r)
    end

    def self.revision_from_table(model, table)
      model.mapper.revision_from_table(table)
    end

    def self.tables(model)
      mapper = model.mapper
      model.database.tables.select { |t| mapper.revision_table?(t) }.sort
    end

    def self.table(model, revision = nil)
      new(model, revision).table
    end

    def self.table?(model, table)
      model.mapper.revision_table?(table)
    end

    attr_reader :revision

    def initialize(model, revision)
      @model, @revision = model, revision
    end

    def create(&block)
      validate!
      generator = Generator.new(self)
      generator.create(&block)
      self
    end

    def patch(modified, &block)
      return create(&block) if must_publish_all?(modified)
      validate!
      modified = Array(modified).map { |m|
        m.is_a?(@model) ? m.reload : @model.get(m)
      }
      patcher = Patcher.new(self, modified)
      patcher.create(&block)
      self
    end

    def must_publish_all?(modified)
      Array(modified).empty? || !previous.revision_exists?
    end

    def validate!
      raise InvalidRevision, "Revision '#{@revision.inspect}' is not > 0" if !creatable?
    end

    def creatable?
      !@revision.nil? && (@revision > 0)
    end

    def delete
      return self unless creatable?
      delete_table
      history_dataset.delete
      archive_dataset.delete
      self
    end

    def delete_table
      database.drop_table?(table)
    end

    def table_exists?
      database.tables.include?(table)
    end

    def revision_exists?
      return false if @revision.nil?
      history_dataset.count > 0
    end

    def exists?
      revision_exists?
    end

    def unarchive
      return if revision_exists?
      copy_dataset(archive_dataset, history_table)
    end

    def mapper
      @model.mapper
    end

    def database
      @model.database
    end

    alias_method :db, :database

    def transaction
      database.transaction do
        @model.with_editable do
          yield
        end
      end
    end

    def scope
      @model.with_revision(@revision) do
        yield
      end
    end

    def complete
      copy_to(history_table)
      copy_to(archive_table)
    end

    def copy_to(dest_table)
      copy_dataset(dataset, dest_table)
    end

    def copy_dataset(ds, dest_table)
      db.run("INSERT INTO #{db.literal(dest_table)} #{ds.select_sql}")
    end

    def previous
      revision = (@revision.nil? || @revision <= 1) ? nil : @revision - 1
      Revision.new(@model, revision)
    end

    def table
      mapper.revision_table(@revision)
    end

    def dataset
      db[table]
    end

    def content_table
      mapper.base_table
    end

    def content_dataset
      db[content_table]
    end

    def history_table
      mapper.revision_history_table
    end

    def history_dataset(&block)
      _dataset(history_table, &block)
    end

    def archive_table
      mapper.revision_archive_table
    end

    def archive_dataset(&block)
      _dataset(archive_table, &block)
    end

    def _dataset(table, &block)
      db[table].filter(:revision => @revision, &block)
    end
  end
end
