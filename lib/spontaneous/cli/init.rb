# encoding: UTF-8

require 'etc'

module Spontaneous::Cli
  class Init < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace :init

    default_task :init

    desc :init, "Creates databases and initialises a new Spontaneous site"

    method_option :user, :type => :string, :default => "root", :aliases => "-u", :desc => "Database admin user"
    method_option :password, :type => :string, :default => "", :aliases => "-p", :desc => "Database admin password"
    method_option :account, :type => :hash, :default => {}, :aliases => "-a", :desc => "Details of the root login"

    def init
      prepare :init
      site = ::Spontaneous::Site.instantiate(Dir.pwd, options.environment, :back)
      Sequel.extension :migration

      database, connection_params = admin_connection_params

      [database, "#{database}_test"].each do |db|
        create(db, connection_params)
        migrate(db, connection_params)
      end

      boot!

      # Add a root user if this is a new site
      insert_root_user if ::Spontaneous::Permissions::User.count == 0

    end

    protected

    def insert_root_user
      p options.account
      invoke "user:add", [],  options.account
      # Set up auto_login configuration with the name of the root user
      # we've just created
      root = ::Spontaneous::Permissions::User.first
      config_path = "./config/environments/development.rb"
      config = File.read(config_path, encoding: "UTF-8").
        gsub(/__SPONTANEOUS_ROOT_USER_INSERT__/, root.login)
      File.write(config_path, config, encoding: "UTF-8")
    end

    def create(database, db_config)
      Sequel.connect(db_config) do |connection|
        begin
          say "  >> Creating database `#{database}`", :green
          create_database(connection, database)
        rescue => e
          say " >>> Unable to create #{db_config[:adapter]} database `#{database}`:\n   > #{e}", :red
        end
      end
    end

    def migrate(database, db_config)
      Sequel.connect(db_config.merge(:database => database)) do |connection|
        begin
          connection.logger = nil
          say "  >> Running migrations..."
          Sequel::Migrator.apply(connection, ::Spontaneous.gem_dir('db/migrations'))
          say "  >> Done"
        rescue => e
          say " >>> Error running migrations on database `#{database}`:\n   > #{e}", :red
        end
      end
    end

    # Converts the site db parameters into 'admin' connection using the provided
    # db credentials and the necessary :database settings
    def admin_connection_params
      site_connection_params = ::Spontaneous.db_settings
      connection_params = site_connection_params.merge({
        :user     => options.user,
        :password => options.password
      })
      database = connection_params.delete(:database)
      case connection_params[:adapter]
      when /mysql/
      when /postgres/
        # postgres requires that you connect to a db.
        # "postgres" is guaranteed to exist
        connection_params[:database] = "postgres"
      end
      [database, connection_params]
    end

    def create_database(connection, database)
      command = case connection.database_type
                when :postgres
                  %(CREATE DATABASE "#{database}" TEMPLATE=template0 ENCODING='UTF8')
                when :mysql
                  "CREATE DATABASE `#{database}` CHARACTER SET UTF8"
                end
      connection.run(command)
    end
  end # Init
end # Spontaneous::Cli
