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
    method_option :create_user, :type => :boolean, :default => true, :desc => "Enable creation of a root user"

    def init
      initialize_site
    end

    protected

    def initialize_site
      prepare :init

      @site = ::Spontaneous::Site.instantiate(Dir.pwd, options.environment, :console)
      Sequel.extension :migration

      site_initializer.run(@site.environment)

      boot!

      # Add a root user if this is a new site
      insert_root_user if (options.create_user && ::Spontaneous::Permissions::User.count == 0)
    end

    class DatabaseInitializer
      def initialize(cli, site)
        @cli, @site = cli, site
      end

      def run(environment)
        initialize_databases(environment)
      end

      def initialize_databases(environment)
        database_initializers(environment).each do |initializer|
          initializer.run
        end
      end

      # Returns a list of initializers for the given env.
      #
      # This de-dupes the initializers according to the config so that only
      # one call is made in the case where different envs return the same db
      # config.
      def database_initializers(environment)
        dbs = database_environments(environment).map { |env|
          database_instance(env)
        }.uniq { |db| db.opts }
        dbs.map { |db| initializer_for_db(db) }
      end

      def database_initializer(env)
        initializer_for_db(database_instance(env))
      end

      def initializer_for_db(db)
        initializer_class = case db.opts[:adapter]
        when /mysql/
          'MySQL'
        when /postgres/
          'Postgresql'
        when /sqlite/
          'Sqlite'
        end
        klass = Spontaneous::Cli::Init.const_get(initializer_class)
        klass.new(@cli, db)
      end

      def database_instance(env)
        @site.database_instance(database_config(env))
      end

      def database_config(env)
        @site.db_connection_options(env)
      end

      def database_environments(environment)
        case environment
        when :development
          [:development, :test]
        else
          [environment]
        end
      end
    end

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

    def site_initializer
      @site_initializer ||= DatabaseInitializer.new(self, @site)
    end
  end # Init
end # Spontaneous::Cli

require 'spontaneous/cli/init/db'
require 'spontaneous/cli/init/postgresql'
require 'spontaneous/cli/init/mysql'
require 'spontaneous/cli/init/sqlite'
