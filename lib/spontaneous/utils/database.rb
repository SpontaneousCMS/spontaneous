
module Spontaneous
  module Utils
    module Database

      def self.dumper_fo_database(database = Spontaneous.database)
        case database
        when ::Sequel::Mysql2::Database
          Spontaneous::Utils::Database::MySQLDumper
        else
          raise "Unsupported adapter #{database.class}"
        end.new(database)
      end

      autoload :MySQLDumper, 'spontaneous/utils/database/mysql_dumper'
    end
  end
end
