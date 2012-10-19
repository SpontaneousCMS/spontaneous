# encoding: UTF-8

require 'etc'

module Spontaneous::Cli
  class Init < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace :init

    default_task :init

    desc :init, "Creates databases and initialises a new Spontaneous site"

    method_option :user, :type => :string, :default => nil, :aliases => "-u", :desc => "Database admin user"
    method_option :password, :type => :string, :default => "", :aliases => "-p", :desc => "Database admin password"
    method_option :account, :type => :hash, :default => {}, :aliases => "-a", :desc => "Details of the root login"

    def init
      prepare :init

      site = ::Spontaneous::Site.instantiate(Dir.pwd, options.environment, :console)
      Sequel.extension :migration


      database, admin_connection_params, site_connection_params = generate_connection_params

      [database, "#{database}_test"].each do |db|
        config = site_connection_params.merge(:database => db)
        create(db, admin_connection_params, config)
        migrate(db, admin_connection_params, config)
      end

      boot!

      # Add a root user if this is a new site
      insert_root_user if ::Spontaneous::Permissions::User.count == 0

    end

    protected

    def insert_root_user
      invoke "user:add", [],  options.account
      # Set up auto_login configuration with the name of the root user
      # we've just created
      root = ::Spontaneous::Permissions::User.first
      config_path = "./config/environments/development.rb"
      config = File.read(config_path, encoding: "UTF-8").
        gsub(/__SPONTANEOUS_ROOT_USER_INSERT__/, root.login)
      File.open(config_path, "w:UTF-8") do |file|
        file.write(config)
      end
    end

    def create(database, admin_config, site_config)
      Sequel.connect(admin_config) do |connection|
        begin
          say "  >> Creating database `#{site_config[:database]}`", :green
          create_database(connection, site_config)
        rescue => e
          say " >>> Unable to create #{admin_config[:adapter]} database `#{site_config[:database]}`:\n   > #{e}", :red
        end
      end
    end

    def migrate(database, admin_config, site_config)
      Sequel.connect(admin_config.merge(:database => site_config[:database])) do |connection|
        begin
          connection.logger = nil
          say "  >> Running migrations..."
          Sequel::Migrator.apply(connection, ::Spontaneous.gem_dir('db/migrations'))
          say "  >> Done"
        rescue => e
          say " >>> Error running migrations on database `#{site_config[:database]}`:\n   > #{e}", :red
        end
      end
    end

    # Converts the site db parameters into 'admin' connection using the provided
    # db credentials and the necessary :database settings
    def generate_connection_params
      site_connection_params = ::Spontaneous.db_settings
      connection_params = site_connection_params.dup
      connection_params[:user] = options.user unless options.user.blank?
      connection_params[:password] = options.password unless options.password.blank?

      database = connection_params.delete(:database)
      case connection_params[:adapter]
      when /mysql/
      when /postgres/
        # postgres requires that you connect to a db.
        # "postgres" is guaranteed to exist
        connection_params[:database] = "postgres"
      end
      [database, connection_params, site_connection_params]
    end

    def create_database(connection, config)
      commands = case connection.database_type
                when :postgres
                  [
                    [%(CREATE ROLE "#{config[:user]}" LOGIN PASSWORD '#{config[:password]}'), false],
                    [%(CREATE DATABASE "#{config[:database]}" TEMPLATE=template0 ENCODING='UTF8' OWNER="#{config[:user]}"), true]
                  ]
                when :mysql
                  host = config[:host].blank? ? "" : "@#{config[:host]}"
                  [
                    ["CREATE DATABASE `#{config[:database]}` CHARACTER SET UTF8", true],
                    ["GRANT ALL ON `#{config[:database]}`.* TO `#{config[:user]}`#{host} IDENTIFIED BY '#{config[:password]}'", false]
                  ]
                end
      commands.each do |command, raise_error|
        begin
          connection.run(command)
        rescue => e
          raise e if raise_error
        end
      end
    end
  end # Init
end # Spontaneous::Cli
