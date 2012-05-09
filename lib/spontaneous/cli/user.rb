
module Spontaneous
  module Cli
    class User < ::Spontaneous::Cli::Thor
      Spontaneous = ::Spontaneous
      namespace :user

      default_task :add

      desc "#{namespace}:add", "Add a new user"

      method_option :login,  :type => :string, :aliases => "-l",
        :desc => "The user's login -- must be unique"
      method_option :name,   :type => :string, :aliases => "-n",
        :desc => "The user's name"
      method_option :email,  :type => :string, :aliases => "-e",
        :desc => "The user's email address"
      method_option :passwd, :type => :string, :aliases => ["-p", "--password"],
        :desc => "The user's password"
      method_option :level, :type => :string, :aliases => "-a",
        :desc => "The user's access level"

      def add
        prepare :adduser, :console
        boot!
        users = Spontaneous::Permissions::User.count
        attrs = {}
        width = 14
        valid_login = /^[a-z0-9_]{3,}$/
        levels = Spontaneous::Permissions::UserLevel.all.map(&:to_s)
        level = nil

        say("\nAll fields are required:\n", :green)
        options_login = options.login
        begin
          if options_login
            attrs[:login] = options_login
            say "Login : ".rjust(width, " ")+" ", :white
            say options_login, :green
            options_login = nil
          else
            attrs[:login] = ask "Login : ".rjust(width, " ")
          end
          say("Login must consist of at least 3 letters, numbers and underscores", :red) unless valid_login === attrs[:login]
        end while attrs[:login] !~ valid_login

        attrs[:name] = options.name || ask("Name : ".rjust(width, " "))

        if options.name
          say "Name : ".rjust(width, " ")+" ", :white
          say options.name, :green
        end

        attrs[:email] = options.email || ask("Email : ".rjust(width, " "))

        if options.email
          say "Email : ".rjust(width, " ")+" ", :white
          say options.email, :green
        end

        options_passwd = options.passwd
        begin
          if options_passwd
            attrs[:password] = options_passwd
            say "Password : ".rjust(width, " ")+" ", :white
            say options_passwd, :green
            options_passwd = nil
          else
            attrs[:password] = ask "Password : ".rjust(width, " ")
          end

          say("Password must be at least 6 characters long", :red) unless attrs[:password].length > 5
        end while attrs[:password].length < 6

        if users == 0
          level = "root"
        else
          options_level = options.level
          begin
            if options_level
              level = options_level
              say "User level : ".rjust(width, " ")+" ", :white
              say options_level, :green
              options_level = nil
            else
              level = ask("User level [#{levels.join(', ')}] : ")
            end
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
    end
  end
end

