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
            end
          end
          boot!
          Spontaneous.database.logger = nil
          say "  >> Running migrations..."
          Sequel::Migrator.apply(Spontaneous.database, Spontaneous.gem_dir('db/migrations'))
          say "  >> Done"
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

      desc :adduser, "Add a user"
      def adduser
        prepare :adduser
        boot!
        users = Spontaneous::Permissions::User.count
        attrs = {}
        width = 12
        valid_login = /^[a-z0-9_]{3,}$/
        levels = Spontaneous::Permissions::UserLevel.all.map(&:to_s)
        level = nil

        say("\nAll fields are required:\n", :green)
        begin
          attrs[:login] = ask "Login : ".rjust(width, " ")
          say("Login must consist of at least 3 letters, numbers and underscores", :red) unless valid_login === attrs[:login]
        end while attrs[:login] !~ valid_login

        attrs[:name] = ask "Name : ".rjust(width, " ")
        attrs[:email] = ask "Email : ".rjust(width, " ")

        begin
          attrs[:password] = ask "Password : ".rjust(width, " ")
          say("Password must be at least 6 characters long", :red) unless attrs[:password].length > 5
        end while attrs[:password].length < 6

        if users == 0
          level = "root"
        else
          begin
            level = ask("User level [#{levels.join(', ')}] : ")
            say("Invalid level '#{level}'", :red) unless levels.include?(level)
          end while !levels.include?(level)
        end

        attrs[:password_confirmation] = attrs[:password]
        user = Spontaneous::Permissions::User.new(attrs)

        if user.save
          user.update(:level => level)
          say("\nUser '#{user.login}' created with level '#{user.level}'", :green)
        else
          errors = user.errors.map do | a, e |
            " - '#{a.to_s.capitalize}' #{e.first}"
          end.join("\n")
          say("\nInvalid user details:\n"+errors, :red)
        end
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
