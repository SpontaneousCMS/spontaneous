# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class Postgresql < Db

      def admin_connection_params
        config = super
        config.merge(database: 'postgres')
      end

      # On some machines the db creation fails due to incompabilities between the UTF8 encoding
      # and the configured locale.
      # You can force a locale for the db by adding LC_COLLATE & LC_CTYPE params
      # to the CREATE command:
      #
      #   LC_COLLATE='C.UTF-8' LC_CTYPE='C.UTF-8'
      #
      # but I don't know a good/the best way to determine the most appropriate UTF-8 locale
      # C.UTF-8 doesn't exist on OS X.
      def create_database_commands(opts)
        create_cmd = %(CREATE DATABASE "#{opts[:database]}" WITH TEMPLATE=template0 ENCODING='UTF8')
        cmds = []
        unless opts[:user].blank?
          create_cmd << %( OWNER="#{opts[:user]}")
          cmds << [%(CREATE ROLE "#{opts[:user]}" LOGIN PASSWORD '#{opts[:password]}'), false]
        end
        cmds << [create_cmd, true]
      end
    end
  end
end
