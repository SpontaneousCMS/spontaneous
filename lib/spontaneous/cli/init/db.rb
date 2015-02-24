# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class Db

      attr_reader :database, :config

      def initialize(cli, database)
        @cli = cli
        @database = database
      end

      def run
        create
        migrate
      end

      def create
        Sequel.connect(admin_connection_params) do |connection|
          begin
            @cli.say "  >> Creating database `#{database.opts[:database]}`", :green
            create_database(connection)
          rescue => e
            @cli.say " >>> Unable to create #{connection.opts[:adapter]} database `#{database.opts[:database]}`:\n   > #{e}", :red
          end
        end
      end

      def migrate
        begin
          database.logger = nil
          @cli.say "  >> Running migrations..."
          Sequel::Migrator.apply(database, ::Spontaneous.gem_dir('db/migrations'))
          @cli.say "  >> Done"
        rescue => e
          @cli.say " >>> Error running migrations on database `#{site_config[:database]}`:\n   > #{e}", :red
          raise e
        end
      end

      def create_database(connection)
        commands = create_database_commands(database.opts)
        commands.each do |command, raise_error|
          begin
            connection.run(command)
          rescue => e
            raise e if raise_error
          end
        end
      end

      # connect to the database as a super/root user in order to create
      # the database
      def admin_connection_params
        config = @database.opts.dup
        config.delete(:database)
        config[:user] = options.user unless options.user.blank?
        config[:password] = options.password unless options.password.blank?
        config
      end

      # Override in db specific sub-classes
      def create_database_commands(opts)
        [["", false]]
      end

      def options
        @cli.options
      end
    end
  end
end
