# encoding: UTF-8

require 'thor/group'

module Spontaneous
  module Generators
    class Site < Thor::Group
      def self.available_dbs
        %w(mysql postgres)
      end

      def self.source_root; File.expand_path(File.dirname(__FILE__) + "/site"); end
      def self.banner; "spot generate site [domain]"; end

      include Thor::Actions

      class_option :root,    :desc => "The root destination", :aliases => '-r', :default => ".",   :type => :string
      class_option :database,    :desc => "The database to use ('mysql' (default) or 'postgres')", :aliases => '-d', :default => "mysql",   :type => :string
      class_option :dbpwd,    :desc => "The password for the database root user", :aliases => '-p', :default => "",   :type => :string

      argument :domain, :type => :string, :desc => "The domain name of the site to generate"

      desc "Generates a new site for DOMAIN"
      def create_site
        if self.class.available_dbs.include?(options.database)
          @valid = true
          say "Generating '#{domain}'...", :bold
          @domain = domain
          @site_name = domain.to_s.gsub(/\./, "_")
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
          empty_directory "cache/media/tmp"
          empty_directory "cache/revisions"
          copy_file ".gitignore"
          template "lib/tasks/site.rake.tt", "lib/tasks/#{@site_name}.rake"
        else
          @valid = false
          say "Invalid database selection '#{options.database}'. Valid options are: #{available_dbs.join(', ')}", :red
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

        Then go to http://spontaneouscms.org/docs
        and read the many useful guides to getting started with Spontaneous.

        MSG
        say(message)
      end
    end # Site
  end # Generators
end # Spontaneous

