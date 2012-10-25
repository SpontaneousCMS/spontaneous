
module ::Spontaneous
  module Cli
    class User < ::Thor
      include Spontaneous::Cli::TaskUtils

      namespace    :user
      default_task :add

      desc "add", "Add a new user"

      method_option :login,  :type => :string, :aliases => "-l",
        :desc => "The user's login -- must be unique"
      method_option :name,   :type => :string, :aliases => "-n",
        :desc => "The user's name"
      method_option :email,  :type => :string, :aliases => "-e",
        :desc => "The user's email address"
      method_option :password, :type => :string, :aliases => ["-p", "--passwd"],
        :desc => "The user's password"
      method_option :level, :type => :string, :aliases => "-a",
        :desc => "The user's access level"

      def add
        prepare! :adduser, :console

        users = ::Spontaneous::Permissions::User.count

        defaults = find_defaults(users)

        say("\nAll fields are required:\n", :green)

        attrs, level = ask_user_details(defaults, users)

        user = ::Spontaneous::Permissions::User.new(attrs)

        if user.save
          user.update(:level => level)
          say("\nUser '#{user.login}' created with level '#{user.level}'", :green)
        else
          errors = user.errors.map do | a, e |
            " - #{a.to_s.capitalize} #{e.first} #{attrs[a].inspect}"
          end.join("\n")
          say("\nUnable to create user:\n"+errors, :red)
          exit 127
        end
      end


      desc "list", "List the current users"
      method_option :bare, :type => :boolean, :default => false, :aliases => %w(-b),
        :desc => "Remove descriptive text from result"
      def list
        prepare! :listusers, :console
        user_table(::Spontaneous::Permissions::User.all, options.bare)
      end


      desc "authenticate LOGIN PASSWORD", "Test a user/password combination"
      method_option :bare, :type => :boolean, :default => false, :aliases => %w(-b),
        :desc => "Remove descriptive text from result"

      def authenticate(login, password)
        prepare! :user_authenticate, :console
        key = Spontaneous::Permissions::User.authenticate login, password
        if key
          say "\nAuthentication successful for user '#{login}'", :green unless options.bare
          user_table([key.user], options.bare)
        else
          say "\nInvalid username & password combination", :red
          exit 127
        end
      end

      protected

      def user_table(users, hide_headers = false)
        columns = [:login, :name, :email, :level]
        users = ::Spontaneous::Permissions::User.all.map { |user|
          columns.map { |column| user.send(column) }
        }
        users.unshift columns.map { |c| c.to_s.capitalize } unless hide_headers
        puts "\n" unless hide_headers
        print_table(users, indent: (hide_headers ? 0 : 2))
        puts "\n"
      end

      def find_defaults(existing_user_count)
        return {} if existing_user_count > 0

        require 'etc'

        defaults = { login: Etc.getlogin }
        git_installed = Kernel.system "which git > /dev/null 2>&1"

        if git_installed
          defaults[:email] = `git config --get user.email`.chomp
          defaults[:name]  = `git config --get user.name`.chomp
        end
        defaults
      end

      def prompt(attribute, default = nil, width = 14)
        prompt = (attribute.to_s.capitalize).rjust(width, " ")
        prompt << " :"
        prompt << %( [#{default}]) if default
        prompt
      end

      def request(attribute, default, value = nil)
        if value
          say prompt(attribute)+" ", :white
          say value, :green
          return value
        else
          if block_given?
            return yield
          else
            return ask_with_default(attribute, default)
          end
        end
      end

      def ask_with_default(attribute, default = nil)
        result = ask(prompt(attribute, default))
        return default if default && result == ""
        result
      end

      def ask_user_details(defaults = {}, users)
        attrs = {}
        level = nil
        width = 14
        valid_login = /^[a-z0-9_]{3,}$/
        levels = ::Spontaneous::Permissions::UserLevel.all.map(&:to_s)

        attrs[:login] = request(:login, defaults[:login], options.login) do
          begin
            login =  ask_with_default(:login, defaults[:login])
            say("Login must consist of at least 3 letters, numbers and underscores", :red) unless valid_login === login
          end while login !~ valid_login
          login
        end

        attrs[:name]     = request(:name, defaults[:name], options.name)
        attrs[:email]    = request(:email, defaults[:email], options.email)
        attrs[:password] = request(:password, nil, options.password) do
          begin
            passwd = ask_with_default(:password)
            say("Password must be at least 6 characters long", :red) unless passwd.length > 5
          end while passwd.length < 6
          passwd
        end

        if users == 0
          level = "root"
        else
          level = options.level
          unless level.blank? or levels.include?(level)
            say("\nInvalid level '#{level}'", :red)
            say("Valid levels are: #{levels.join(", ")}", :red)
            exit 127
          end
          level = request(:level, nil, level) do
            begin
              level = ask(prompt("User level")+ " [#{levels.join(', ')}]")
              say("Invalid level '#{level}'", :red) unless levels.include?(level)
            end while !levels.include?(level)
            level
          end
        end
        [attrs, level]
      end
    end
  end
end

