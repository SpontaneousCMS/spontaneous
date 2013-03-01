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
          :dataset => :"#{name}_mapper_dataset"
        }
      end

      def_delegators :dataset,
        :filter, :where,
        :filter!, :where!,
        :count, :count!,
        :order, :limit,
        :all, :get, :[], :first,
        :all!, :first!,
        :reload,
        :instance,
        :create, :save, :insert,
        :update, :update!,
        :delete, :delete_instance,
        :for_update, :select,
        :columns, :table_name,
        :qualify_column, :quote_identifier,
        :with_cache,
        :logger=, :logger

      def_delegators :@schema,
        :subclasses, :inherited

      def_delegators :@table,
        :db, :primary_key,
        :revision_table, :revision_table?, :revision_from_table,
        :revision_history_table, :revision_archive_table,
        :revision_history_dataset, :revision_archive_dataset,
        :quote_identifier

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

      def scope(revision, visible, &block)
        if use_current_scope?(revision, visible)
          if block_given?
            yield
          else
            dataset
          end
        else
          scope!(revision, visible, &block)
        end
      end

      def scope!(revision, visible, &block)
        if block_given?
          r, v, d  = @keys.values_at(:revision, :visible, :dataset)
          thread   = Thread.current
          state    = [thread[r], thread[v], thread[d]]
          begin
            thread[r] = to_revision(revision)
            thread[v] = visible
            thread[d] = current_scope
            yield
          ensure
            thread[r], thread[v], thread[d] = state
          end
        else
          scope_for(revision, visible)
        end
      end

      def dataset
        Thread.current[@keys[:dataset]] || current_scope
      end

      def cached_dataset?
        !Thread.current[@keys[:dataset]].nil?
      end

      def use_current_scope?(revision, visible)
        cached_dataset? &&
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

      private

      def current_scope
        scope_for(current_revision, visible_only?)
      end

      def scope_for(revision, visibility)
        Scope.new(revision, visibility, @table, @schema)
      end
    end
  end
end
