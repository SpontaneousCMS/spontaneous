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

      attr_reader :schema

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
        :columns, :qualify_column, :quote_identifier,
        :with_cache,
        :logger, :logger=

      def_delegators :@schema, :subclasses, :inherited

      def visible(visible_only = true, &block)
        scope(current_revision, visible_only, &block)
      end

      def revision(r = current_revision, &block)
        scope(r, visible_only?, &block)
      end

      def editable(&block)
        revision(nil, &block)
      end

      def scope(revision, visible, &block)
        if use_current_scope?(revision, visible)
          if block_given?
            yield
          else
            dataset
          end
        else
          with_scope(revision, visible, &block)
        end
      end

      def with_scope(revision, visible, &block)
        if block_given?
          r, v, d  = @keys.values_at(:revision, :visible, :dataset)
          thread   = Thread.current
          state    = [thread[r], thread[v], thread[d]]
          begin
            thread[r] = revision_number(revision)
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

      def use_current_scope?(revision, visible)
        cached_dataset? &&
          (current_revision == revision_number(revision)) &&
          ((visible || false) == visible_only?)
      end

      def revision_number(r)
        r.nil? ? nil : r.to_i
      end

      def current_revision
        Thread.current[@keys[:revision]]
      end

      def visible_only?
        Thread.current[@keys[:visible]] || false
      end

      def db
        @table.db
      end

      def revision_table(revision)
        @table.revision_table(revision)
      end

      def revision_table?(table_name)
        @table.revision_table?(table_name)
      end

      def quote_identifier(identifier)
        @table.quote_identifier(identifier)
      end

      def schema_uid(id_string)
        @schema.uids[id_string]
      end

      def dataset
        Thread.current[@keys[:dataset]] || current_scope
      end

      def cached_dataset?
        !Thread.current[@keys[:dataset]].nil?
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
