module Spontaneous
  module DataMapper
    class ContentTable
      REVISION_PADDING = 5

      attr_reader :name, :database

      def initialize(name, database)
        @name, @database = name, database
      end

      def columns
        dataset.columns
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
        return @name if revision_number.nil?
        "__r#{pad_revision_number(revision_number)}_#{@name}".to_sym
      end

      def revision_table?(table_name)
        /\A__r\d{#{REVISION_PADDING}}_#{@name}\z/ === table_name.to_s
      end

      def pad_revision_number(revision_number)
        revision_number.to_s.rjust(REVISION_PADDING, "0")
      end
    end
  end
end
