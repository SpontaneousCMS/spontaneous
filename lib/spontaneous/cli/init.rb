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
      initialize_size
    end

    protected

    def initialize_size
      prepare :init

      @site = ::Spontaneous::Site.instantiate(Dir.pwd, options.environment, :console)
      Sequel.extension :migration

      database_initializer.run

      boot!

      # Add a root user if this is a new site
      insert_root_user if (options.create_user && ::Spontaneous::Permissions::User.count == 0)
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

    def database_initializer
      @database_initializer ||= get_database_initializer
    end

    def get_database_initializer
      # Sequel doesn't try to connect to the db by default so this is a very light-weight op
      connection_params = @site.database_instance.opts
      classname = case connection_params[:adapter]
      when /mysql/
        'MySQL'
      when /postgres/
        'Postgresql'
      when /sqlite/
        'Sqlite'
      end
      klass = Spontaneous::Cli::Init.const_get(classname)
      klass.new(connection_params, self)
    end
  end # Init
end # Spontaneous::Cli

require 'spontaneous/cli/init/db'
require 'spontaneous/cli/init/postgresql'
require 'spontaneous/cli/init/mysql'
require 'spontaneous/cli/init/sqlite'
