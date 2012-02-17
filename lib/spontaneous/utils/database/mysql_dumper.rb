
module Spontaneous
  module Utils
    module Database
      class MySQLDumper
        def initialize(database)
          @database = database
        end

        def load(path)
          system(load_command(path))
        end

        def load_command(path)
          options = [
            "mysql",
            option(:password),
            option(:user),
            option(:default_character_set),
            database_name
          ]
          if path =~ /\.gz$/
            options = ["gunzip", "<", path, "|"].concat(options)
          end

          command = options.join(" ")
        end

        def dump(path, tables = nil)
          system(dump_command(path, tables))
        end

        def dump_command(path, tables = nil)
          options = [
            option(:password),
            option(:user),
            option(:default_character_set),
            database_name
          ]
          unless tables.nil?
            options.push(tables.join(" "))
          end

          options.push( "| gzip") if path =~ /\.gz$/

          command = %(mysqldump #{options.join(" ")} > #{path} )
        end
        def database_name
          @database.opts[:database]
        end

        def user
          @database.opts[:user]
        end

        def password
          @database.opts[:password]
        end

        def default_character_set
          "UTF8"
        end

        def option(option, add_if_nil=false)
          value = self.send(option)
          if !value.nil? or add_if_nil
            "--#{option.to_s.gsub(/_/, '-')}=#{value}"
          else
            ""
          end
        end
      end
    end
  end
end
