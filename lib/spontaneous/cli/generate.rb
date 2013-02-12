# encoding: UTF-8

require 'public_suffix'

module Spontaneous::Cli
  class Generate < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace :generate

    default_task :site

    desc "site [DOMAIN]", "Generates a site skeleton. Usage: spot generate <site domain name>"

    method_option :database, :type => :string, :default => "mysql", :aliases => "-d", :desc => "Database adapter"
    method_option :user, :type => :string, :default => "root", :aliases => "-u", :desc => "Database admin user"
    method_option :password, :type => :string, :default => "", :aliases => "-p", :desc => "Database admin user"

    def site(*args)
      # require "spontaneous"
      ::Spontaneous::Generators::Site.start(ARGV.drop_while { |e| %w(generate site).include?(e) })
    end

    def method_missing(method, *args)
      if PublicSuffix.valid?(method.to_s)
        puts method
        args.unshift(method.to_s)
        ARGV.unshift("site")
        self.send(:site, *args)
      else
        super
      end
    end
  end # Generate
end # Spontaneous::Cli

