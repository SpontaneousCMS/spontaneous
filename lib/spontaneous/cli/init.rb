# encoding: UTF-8

module Spontaneous::Cli
  class Init < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace :init

    default_task :init

    desc :init, "Creates databases and initialises a new Spontaneous site"
    def init
      prepare :init
      site = ::Spontaneous::Site.instantiate(Dir.pwd, options.environment, :back)
      require File.expand_path('../../../spontaneous', __FILE__)
      Sequel.extension :migration
      connection_params = ::Spontaneous.db_settings
      connection_params[:user] = 'root'
      database = connection_params.delete(:database)
      password = connection_params.delete(:password)
      catch(:error) do
        Sequel.connect(connection_params) do |connection|
          ["", "_test"].map { |ext| "#{database}#{ext}"}.each do |db|
            begin
              say "  >> Creating database `#{db}`"
              connection.run("CREATE DATABASE `#{db}` CHARACTER SET UTF8")
            rescue => e
              say " >>> Unable to create #{connection_params[:adapter]} database `#{db}`:\n   > #{e}", :red
              # throw :error
            end
            begin
              connection.run("USE `#{db}`")
              connection.logger = nil
              say "  >> Running migrations..."
              Sequel::Migrator.apply(connection, ::Spontaneous.gem_dir('db/migrations'))
              say "  >> Done"
            rescue => e
              say " >>> Error running migrations on database `#{db}`:\n   > #{e}", :red
            end
          end
        end
        boot!
      end
    end

  end # Init
end # Spontaneous::Cli
