# encoding: UTF-8

require 'thor/group'

module Spontaneous
  module Generators
    class Site < Thor::Group
      def self.available_dbs
        { "mysql"      => { :gem => "mysql2", :adapter => "mysql2" },
          "postgresql" => { :gem => "pg", :adapter => "postgres" },
          "postgres"   => { :gem => "pg", :adapter => "postgres" } }
      end

      def self.source_root; File.expand_path(File.dirname(__FILE__) + "/site"); end
      def self.banner; "spot generate site [domain]"; end

      include Thor::Actions

      argument :domain, :type => :string, :desc => "The domain name of the site to generate"

      class_option :root,    :desc => "The root destination", :aliases => '-r', :default => ".",   :type => :string
      class_option :database,    :desc => "The database to use ('mysql' (default) or 'postgres')", :aliases => %w(-d --db), :default => "mysql",   :type => :string
      class_option :user,    :desc => "The database account to use", :aliases => '-u', :default => "root",   :type => :string
      class_option :password,    :desc => "The password for the database user", :aliases => %w(-p), :default => "",   :type => :string
      class_option :host,    :desc => "The database host", :aliases => %w(-h), :default => "",   :type => :string


      desc "Generates a new site for DOMAIN"
      def create_site
        if self.class.available_dbs.keys.include?(options.database)
          spec = Gem::Specification.load(File.expand_path("../../../../spontaneous.gemspec", __FILE__))
          adapter = self.class.available_dbs[options.database]
          adapter_dependency =  spec.development_dependencies.detect { |dependency| dependency.name == adapter[:gem] }
          @valid = true
          say "Generating '#{domain}'...", :bold
          @domain = domain
          @site_name = domain.to_s.gsub(/\./, "_")
          @username  = domain.split(/\./).first
          @database  = { :user => options.user, :adapter => adapter[:adapter], :gem => adapter_dependency, :password => options.password, :host => options.host }
          self.destination_root = options[:root]
          empty_directory(@site_name)
          self.destination_root = self.destination_root / @site_name
          directory "config"
          directory "schema"
          directory "templates"
          directory "public"
          template "Gemfile.tt", "Gemfile"
          template "Capfile.tt", "Capfile"
          template "Rakefile.tt", "Rakefile"
          template "lib/site.rb.tt", "lib/site.rb"
          empty_directory "lib/tasks"
          empty_directory "log"
          empty_directory "tmp"
          empty_directory "cache/media"
          empty_directory "cache/tmp"
          empty_directory "cache/revisions"
          copy_file ".gitignore"
          template "lib/tasks/site.rake.tt", "lib/tasks/#{@site_name}.rake"
        else
          @valid = false
          say "Invalid database selection '#{options.database}'. Valid options are: #{self.class.available_dbs.keys.join(', ')}", :red
        end
      end

      def finish_message
        return unless @valid
        message = (<<-MSG).gsub(/^ +/, '')


        =========================================================

        Site #{@domain} is ready.

        To start using your new CMS do the following:
        ---------------------------------------------------------
        1. cd #{options[:root]}/#{@site_name}
        2. bundle install
        3. spot init

        Then go to

          http://spontaneous.io/documentation

        and read the many useful guides to getting started with Spontaneous.

        MSG
        say(message)
      end
    end # Site
  end # Generators
end # Spontaneous

