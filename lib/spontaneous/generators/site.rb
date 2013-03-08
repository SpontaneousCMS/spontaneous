# encoding: UTF-8

require 'thor/group'

module Spontaneous
  module Generators
    class Site < Thor::Group
      def self.available_dbs
        postgres = { :gem => "pg", :adapter => "postgres", :user => nil }
        { "mysql"      => { :gem => "mysql2", :adapter => "mysql2", :user => "root" },
          "pg" => postgres,  "postgresql" =>  postgres, "postgres"   =>  postgres }
      end

      def self.source_root; File.expand_path(File.dirname(__FILE__) + "/site"); end
      def self.banner; "spot generate site [domain]"; end

      include Thor::Actions

      argument :domain, :type => :string, :desc => "The domain name of the site to generate"

      class_option :root,     :desc => "The root destination", :aliases => '-r', :default => ".",   :type => :string
      class_option :database, :desc => "The database to use ('mysql' (default) or 'postgres')", :aliases => %w(-d --db), :default => "mysql",   :type => :string
      class_option :user,     :desc => "The database account to use", :aliases => '-u', :type => :string
      class_option :password, :desc => "The password for the database user", :aliases => %w(-p), :default => "",   :type => :string
      class_option :host,     :desc => "The database host", :aliases => %w(-h),   :type => :string


      desc "Generates a new site for DOMAIN"
      def create_site
        if self.class.available_dbs.keys.include?(options.database)
          say "Generating '#{domain}'...", :bold
          @domain    = domain
          @site_name = domain.to_s.gsub(/\./, "_")
          @username  = domain.split(/\./).first
          @database  = {
            :user => options.user || adapter[:user],
            :adapter => adapter[:adapter],
            :gem => adapter_dependency,
            :password => options.password,
            :host => options.host
          }
          self.destination_root = options[:root]
          empty_directory(@site_name)
          self.destination_root = self.destination_root / @site_name
          # template "lib/tasks/site.rake.tt", "lib/tasks/#{@site_name}.rake"
        else
          say "Invalid database selection '#{options.database}'. Valid options are: #{self.class.available_dbs.keys.join(', ')}", :red
          exit 1
        end
      end

      def generate
        directory "config"
        directory "schema"
        directory "lib"
        directory "templates"
        directory "assets"
        directory "public"
        template "Gemfile.tt", "Gemfile"
        template "Capfile.tt", "Capfile"
        template "Rakefile.tt", "Rakefile"
        # template "lib/site.rb.tt", "lib/site.rb"
        # empty_directory "lib/tasks"
        empty_directory "log"
        empty_directory "tmp"
        empty_directory "cache/media"
        empty_directory "cache/tmp"
        empty_directory "cache/revisions"
        copy_file ".gitignore"
      end

      def finish_message_1
        message = (<<-MSG).gsub(/^ +/, '')


        =========================================================

        Site #{@domain} is ready.

        MSG
        say(message, :bold)
      end

      def finish_message_2
        message = (<<-MSG).gsub(/^ +/, '')
        To start using your new CMS do the following:
        ---------------------------------------------------------
        MSG
        say(message)
      end

      def finish_message_3
        message = (<<-MSG).gsub(/^ +/, '')
        1. cd #{options[:root]}/#{@site_name}
        2. bundle install
        3. spot init
        MSG
        say(message.chomp, :green)
      end

      def finish_message_4
        message = (<<-MSG).gsub(/^ +/, '')
        ---------------------------------------------------------

        Then go to

          http://spontaneous.io/

        and read the many useful guides to getting started with
        Spontaneous.

        MSG
        say(message)
      end

      private

      def adapter
        self.class.available_dbs[options.database]
      end

      # Source adapter versions from Spontaneous's gemfile. This way
      # sites are generated using the same version that tests are run against
      def adapter_dependency
        gemfile = (File.expand_path("../../../../Gemfile", __FILE__))
        saved_gemfile, ENV['BUNDLE_GEMFILE'] = ENV['BUNDLE_GEMFILE'], gemfile
        spec = Bundler::Dsl.new
        spec.eval_gemfile(gemfile)
        ENV['BUNDLE_GEMFILE'] = saved_gemfile
        spec.dependencies.detect { |dependency| dependency.name == adapter[:gem] }
      end
    end # Site
  end # Generators
end # Spontaneous

