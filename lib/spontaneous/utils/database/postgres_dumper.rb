module Spontaneous
  module Utils
    module Database
      class PostgresDumper < MySQLDumper
        def initialize(database)
          @database = database
        end

        def name
          "pgsql"
        end

        def load(path)
          system(load_command(path))
        end

        def load_command(path)
          options = [
            "psql",
            "--quiet",
            option(:password),
            option(:username),
            database_name
          ]
          if path =~ /\.gz$/
            options = ["gunzip", "<", path, "|"].concat(options)
          else
            options.concat [ "<", path ]
          end

          options.concat [ ">/dev/null" ]

          command = options.join(" ")
        end

        def dump(path, tables = nil)
          system(dump_command(path, tables))
        end

        def dump_command(path, tables = nil)
          options = [
            "--clean",
            "--no-owner",
            "--no-privileges",
            option(:password),
            option(:username),
            option(:encoding),
            option(:exclude_table),
            database_name
          ]
          unless tables.nil?
            options.push(tables.join(" "))
          end

          options.push( "| gzip") if path =~ /\.gz$/

          command = %(pg_dump #{options.join(" ")} > #{path} )
        end

        def database_name
          @database.opts[:database]
        end

        def username
          @database.opts[:user]
        end

        def password
          @database.opts[:password]
        end

        def encoding
          "UTF8"
        end

        def exclude_table
          revision_archive_table
        end
      end
    end
  end
end

