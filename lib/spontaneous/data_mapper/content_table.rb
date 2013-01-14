module Spontaneous
  module DataMapper
    class ContentTable
      REVISION_PADDING = 5

      def self.revision_table?(base_name, table_name)
        /\A__r\d+_#{base_name}\z/ === table_name.to_s
      end

      def self.pad_revision_number(revision_number)
        revision_number.to_s.rjust(REVISION_PADDING, "0")
      end

      def self.revision_table(base_name, revision_number)
        return base_name if revision_number.nil?
        "__r#{pad_revision_number(revision_number)}_#{base_name}".to_sym
      end

      # Extracts the revision number from a table name
      #
      #   revision_number :content, :__r00034_content
      #   => 34
      #
      def self.revision_number(base_name, table_name)
        return nil if base_name == table_name
        return nil unless revision_table?(base_name, table_name)
        if (match = /\A__r(\d+)_#{base_name}\z/.match(table_name.to_s))
          rev = match[1]
          return rev.to_i(10)
        end
        nil
      end

      attr_reader :name, :database

      def initialize(name, database)
        @name, @database = name, database
      end

      def columns
        dataset.columns
      end

      def primary_key
        :id
      end

      def dataset(revision = nil)
        @database[revision_table(revision)]
      end

      def logger
        @database.logger
      end

      def logger=(logger)
        @database.logger = logger
      end

      alias_method :db, :database

      def qualify(revision, col)
        Sequel::SQL::QualifiedIdentifier.new(revision_table(revision), col)
      end

      def quote_identifier(identifier)
        dataset.quote_identifier(identifier)
      end

      def revision_table(revision_number)
        self.class.revision_table(@name, revision_number)
      end

      def revision_table?(table_name)
        self.class.revision_table?(@name, table_name)
      end

      def pad_revision_number(revision_number)
        self.class.pad_revision_number(revision_number)
      end
    end
  end
end
