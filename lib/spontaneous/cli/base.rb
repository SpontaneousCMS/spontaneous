# encoding: UTF-8

require 'thor'

module Spontaneous
  module Cli
    class Base < ::Spontaneous::Cli::Thor
      Spontaneous = ::Spontaneous
      include Thor::Actions
      namespace :default

      class InvalidGenerator < Error
        attr_reader :name
        def initialize(name)
          @name = name
          super()
        end
      end







      desc :console, "Gives you console access to the current site"
      def console
        ENV["SPOT_MODE"] = "console"
        prepare :console
        ARGV.clear
        require 'irb'
        boot!
        IRB.setup(nil)
        irb = IRB::Irb.new
        IRB.conf[:MAIN_CONTEXT] = irb.context
        irb.context.evaluate("require 'irb/completion'", 0)
        irb.context.evaluate("require '#{File.expand_path(File.dirname(__FILE__) + '/console')}'", 0)
        # irb.context.evaluate("include Spontaneous", 0)
        trap("SIGINT") do
          irb.signal_handle
        end
        catch(:IRB_EXIT) do
          irb.eval_input
        end
      end

      desc :generate, "Executes the Spontaneous generator with given options."
      def generate(*args)
        require File.expand_path('../../../spontaneous', __FILE__)
        ARGV.shift
        generator_name = ARGV.shift
        generator = nil
        d = Spontaneous::Generators
        case generator_name
        when ''
          raise InvalidGenerator.new(generator_name)
        when 'site'
          generator = d::Site
        when 'page'
          prepare(:generator)
          boot!
          generator = d::Page
        when /[a-zA-Z0-9-]+(\.[a-z]+)+/
          # generator called as 'spot generate domain.com'
          ARGV.unshift(generator_name)
          generator = d::Site
        else
          raise InvalidGenerator.new(generator_name)
        end
        generator.start(ARGV) if generator
      rescue InvalidGenerator => e
        say "Unrecognised generator '#{e.name}'. Available options are:\n\n  #{available_generators.join("\n  ")}\n"
      end

      desc :browse, "Launces a browser pointing to the current development CMS"
      def browse
        prepare :browse
        require 'launchy'
        boot!
        ::Launchy::Browser.run("http://localhost:#{Site.config.port}/@spontaneous")
      end


      desc :init, "Creates databases and initialises a new Spontaneous site"
      def init
        prepare :init
        site = Spontaneous::Site.instantiate(Dir.pwd, options.environment, :back)
        require File.expand_path('../../../spontaneous', __FILE__)
        Sequel.extension :migration
        connection_params = Spontaneous.db_settings
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
                Sequel::Migrator.apply(connection, Spontaneous.gem_dir('db/migrations'))
                say "  >> Done"
              rescue => e
                say " >>> Error running migrations on database `#{db}`:\n   > #{e}", :red
              end
            end
          end
          boot!
        end
      end

      desc :migrate, "Runs migrations"
      def migrate
        prepare :init
        boot!
        Sequel.extension :migration
        connection_params = Spontaneous.db_settings
        say "  >> Running migrations..."
        Sequel::Migrator.apply(Spontaneous.database, Spontaneous.gem_dir('db/migrations'))
        say "  >> Done"
      end

      private


      def available_generators
        Spontaneous::Generators.available.map do |g|
          g.name.demodulize.underscore
        end
      end




    end # Base
  end # Cli
end # Spontaneous
