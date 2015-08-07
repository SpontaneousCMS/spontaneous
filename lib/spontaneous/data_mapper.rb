require "spontaneous/data_mapper/scope"
require "spontaneous/data_mapper/dataset"
require "spontaneous/data_mapper/content_model"
require "spontaneous/data_mapper/content_table"

module Spontaneous
  module DataMapper

    def self.Model(table_name, database, schema, &block)
      table  = ::Spontaneous::DataMapper::ContentTable.new(table_name, database)
      mapper = ScopingMapper.new(table, schema)
      Spontaneous::DataMapper::ContentModel.generate(mapper, &block)
    end

    def self.new(table, schema)
      ScopingMapper.new(table, schema)
    end

    class ScopingMapper
      extend Forwardable

      attr_reader :schema, :table

      def initialize(table, schema)
        @table, @schema = table, schema
        name = table.name
        @keys = {
          :visible  => :"#{name}_mapper_visibility",
          :revision => :"#{name}_mapper_revision",
          :active_scope => :"#{name}_mapper_dataset"
        }
      end

      def_delegators :active_scope,
        :dataset,
        :filter, :filter!,
        :where, :where!,
        :exclude, :exclude!,
        :untyped,
        :count, :count!,
        :order, :limit,
        :all, :get, :[], :first,
        :primary_key_lookup,
        :all!, :first!,
        :reload,
        :instance,
        :create, :save, :insert,
        :update, :update!,
        :delete, :delete_instance,
        :for_update, :select,
        :columns, :table_name,
        :qualify_column, :quote_identifier,
        :with_cache, :clear_cache,
        :sql, :to_sql,
        :logger=, :logger

      def_delegators :@schema,
        :subclasses, :inherited

      def_delegators :@table,
        :db, :primary_key,
        :revision_table, :revision_table?, :revision_from_table,
        :revision_history_table, :revision_archive_table,
        :revision_history_dataset, :revision_archive_dataset,
        :quote_identifier

      def prepare(type, name, *values, &block)
        active_scope.prepare(type, prepared_statement_namespace(name), &block)
      end

      def prepared_statement_namespace(name)
        "#{name}_#{current_revision || "editable"}_#{visible_only?}".to_sym
      end

      def visible(visible_only = true, &block)
        scope(current_revision, visible_only, &block)
      end

      def visible!(visible_only = true, &block)
        scope!(current_revision, visible_only, &block)
      end

      def revision(r = current_revision, &block)
        scope(r, visible_only?, &block)
      end

      def revision!(r = current_revision, &block)
        scope!(r, visible_only?, &block)
      end

      def editable(&block)
        revision(nil, &block)
      end

      def editable!(&block)
        revision!(nil, &block)
      end

      def editable?
        current_revision.nil?
      end

      def with(dataset, &block)
        with!(dataset, &block)
      end

      def with!(dataset, &block)
        scope!(nil, false, dataset, &block)
      end

      def scope(revision, visible, &block)
        if use_current_scope?(revision, visible)
          if block_given?
            yield
          else
            active_scope
          end
        else
          scope!(revision, visible, &block)
        end
      end

      def scope!(revision, visible, dataset = nil, &block)
        if block_given?
          r, v, d  = @keys.values_at(:revision, :visible, :active_scope)
          thread   = Thread.current
          state    = [thread[r], thread[v], thread[d]]
          begin
            thread[r] = to_revision(revision)
            thread[v] = visible
            thread[d] = configured_scope_or_dataset(dataset)
            yield
          ensure
            thread[r], thread[v], thread[d] = state
          end
        else
          scope_for(revision, visible)
        end
      end

      def active_scope
        Thread.current[@keys[:active_scope]] || configured_scope
      end

      def cached_scope?
        !Thread.current[@keys[:active_scope]].nil?
      end

      def use_current_scope?(revision, visible)
        cached_scope? &&
          (current_revision == to_revision(revision)) &&
          ((visible || false) == visible_only?)
      end

      def to_revision(r)
        r.nil? ? nil : r.to_i
      end

      def current_revision
        Thread.current[@keys[:revision]]
      end

      def visible_only?
        Thread.current[@keys[:visible]] || false
      end

      def base_table
        @table.name
      end

      def schema_uid(id_string)
        @schema.uids[id_string]
      end

      def use_prepared_statements?
        db.database_type != :sqlite
      end

      private

      def configured_scope_or_dataset(dataset = nil)
        return configured_scope if dataset.nil?
        scope_with(dataset)
      end

      def configured_scope
        scope_for(current_revision, visible_only?)
      end

      def scope_for(revision, visibility)
        scope_with(ds(revision, visibility))
      end

      def scope_with(dataset)
        Scope.new(dataset, @schema)
      end

      def ds(revision, visibility)
        @table.dataset(revision, visibility)
      end
    end
  end
end
