# encoding: UTF-8

require 'public_suffix'

module Spontaneous::Cli
  class Generate < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace :generate

    default_task :site

    desc "site [DOMAIN]", "Generates a site skeleton. Usage: spot generate <site domain name>"
    def site(*args)
      require File.expand_path('../../../spontaneous', __FILE__)
      ::Spontaneous::Generators::Site.start(args)
    end

    def method_missing(method, *args)
      if PublicSuffix.valid?(method.to_s)
        args.unshift(method.to_s)
        self.send(:site, *args)
      else
        super
      end
    end
  end # Generate
end # Spontaneous::Cli

