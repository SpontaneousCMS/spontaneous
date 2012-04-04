
module Spontaneous
  module Utils
    module Database

      def self.dumper_for_database(database = Spontaneous.database)
        case database.class.to_s
        when "Sequel::Mysql2::Database"
          Spontaneous::Utils::Database::MySQLDumper
        when "Sequel::Postgres::Database"
          Spontaneous::Utils::Database::PostgresDumper
        else
          raise "Unsupported adapter #{database.class}"
        end.new(database)
      end

      autoload :MySQLDumper,    'spontaneous/utils/database/mysql_dumper'
      autoload :PostgresDumper, 'spontaneous/utils/database/postgres_dumper'
    end
  end
end
