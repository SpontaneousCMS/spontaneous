# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class Db

      attr_reader :site_connection_params, :admin_connection_params, :database, :config

      def initialize(connection, cli)
        @cli = cli
        @connection = connection
        # setup_connection_params(connection_settings, @cli.options)
        # @admin_connection_params[:database] = "postgres"
      end

      def run
        databases.each do |site_connection_params, admin_connection_params|
          # config = site_connection_params.merge(:database => db)
          create(admin_connection_params, site_connection_params)
          migrate(site_connection_params)
        end
      end

      def create(admin_config, site_config)
        Sequel.connect(admin_config) do |connection|
          begin
            @cli.say "  >> Creating database `#{site_config[:database]}`", :green
            create_database(connection, site_config)
          rescue => e
            @cli.say " >>> Unable to create #{admin_config[:adapter]} database `#{site_config[:database]}`:\n   > #{e}", :red
          end
        end
      end

      def migrate(site_config)
        Sequel.connect(site_config) do |connection|
          begin
            connection.logger = nil
            @cli.say "  >> Running migrations..."
            Sequel::Migrator.apply(connection, ::Spontaneous.gem_dir('db/migrations'))
            @cli.say "  >> Done"
          rescue => e
            @cli.say " >>> Error running migrations on database `#{site_config[:database]}`:\n   > #{e}", :red
            raise e
          end
        end
      end

      def create_database(connection, config)
        commands = create_database_commands(config)
        commands.each do |command, raise_error|
          begin
            connection.run(command)
          rescue => e
            raise e if raise_error
          end
        end
      end

      def create_database_commands(config)
        [["", false]]
      end

      def setup_connection_params(connection_settings, options)
        @options = options
        @site_connection_params = connection_settings
        @admin_connection_params = @site_connection_params.dup
        @admin_connection_params[:user] = @options.user unless @options.user.blank?
        @admin_connection_params[:password] = @options.password unless @options.password.blank?

        # @database = @admin_connection_params.delete(:database)
      end

      def databases
        environments.map { |env|
          config_for_environment(env)
        }
      end

      def config_for_environment(env)
        site_config = @connection.dup
        admin_config = site_config.dup
        admin_config.delete(:database)
        admin_config[:user] = @cli.options.user unless @cli.options.user.blank?
        admin_config[:password] = @cli.options.password unless @cli.options.password.blank?
        [site_config, admin_config]
      end

      def environments
        case Spontaneous.env
        when :development
          [:development, :test]
        else
          [Spontaneous.env]
        end
      end
    end
  end
end
