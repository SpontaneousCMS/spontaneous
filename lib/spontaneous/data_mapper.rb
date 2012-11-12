require "spontaneous/data_mapper/data_revision"
require "spontaneous/data_mapper/dataset"
require "spontaneous/data_mapper/content_model"
require "spontaneous/data_mapper/content_table"

module Spontaneous
  module DataMapper

    def self.Model(table_name, database, schema, &block)
      table  = ::Spontaneous::DataMapper::ContentTable.new(table_name, database)
      mapper = RevisionMapper.new(table, schema)
      Spontaneous::DataMapper::ContentModel.generate(mapper, &block)
    end

    def self.new(table, schema)
      RevisionMapper.new(table, schema)
    end

    class RevisionMapper
      extend Forwardable

      attr_reader :schema

      def initialize(table, schema)
        @table, @schema = table, schema
      end

      def_delegators :revision,
        :filter, :where,
        :filter!, :where!,
        :count, :count!,
        :order,
        :all, :get, :first,
        :all!, :first!,
        :reload,
        :instance,
        :create, :save, :insert,
        :update, :update!,
        :delete, :delete_instance,
        :for_update, :select,
        :columns, :qualify_column, :quote_identifier,
        :logger, :logger=

      def_delegators :@schema, :subclasses, :inherited

      def visible(visible_only = true, &block)
        if block_given?
          thread_local_scope(:spontaneous_visibility, visible_only, &block)
        else
          data_revision(current_revision, visible_only)
        end
      end

      def revision(r = current_revision, &block)
        if block_given?
          thread_local_scope(:spontaneous_revision, r.nil? ? nil : r.to_i, &block)
        else
          data_revision(r, visible_only?)
        end
      end

      def thread_local_scope(key, value)
        previous_value = Thread.current[key]
        begin
          Thread.current[key] = value
          yield
        ensure
          Thread.current[key] = previous_value
        end
      end

      def editable(&block)
        revision(nil, &block)
      end

      def current_revision
        Thread.current[:spontaneous_revision]
      end

      def visible_only?
        Thread.current[:spontaneous_visibility] || false
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

      private

      def data_revision(revision, visibility)
        DataRevision.new(revision, visibility, @table, @schema)
      end
    end
  end
end
