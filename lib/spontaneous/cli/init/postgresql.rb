# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class Postgresql < Db

      def config_for_environment(env)
        site_config, admin_config = super
        admin_config[:database] = "postgres"
        [site_config, admin_config]
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
      def create_database_commands(config)
        create_cmd = %(CREATE DATABASE "#{config[:database]}" WITH TEMPLATE=template0 ENCODING='UTF8')
        cmds = []
        unless config[:user].blank?
          create_cmd << %( OWNER="#{config[:user]}")
          cmds << [%(CREATE ROLE "#{config[:user]}" LOGIN PASSWORD '#{config[:password]}'), false]
        end
        cmds << [create_cmd, true]
      end
    end
  end
end
