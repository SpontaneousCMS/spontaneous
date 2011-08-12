
module Spontaneous
  module Cli
    class Site < ::Spontaneous::Cli::Thor
      Spontaneous = ::Spontaneous
      namespace :site

      default_task :browse

      desc "#{namespace}:publish", "Publishes the site"
      method_option :changes, :type => :array, :desc => "List of changesets to include"
      method_option :logfile, :type => :string, :desc => "Location of logfile"

      def publish
        prepare :publish
        # TODO: set up logging
        boot!
        ::Site.publishing_method = :immediate
        Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        say "Creating revision #{::Site.revision}", :green, true
        if options.changes
          say ">  Publishing changes #{options.changes.inspect}", :green, true
          ::Site.publish_changes(options.changes)
        else
          say ">  Publishing all", :green, true
          ::Site.publish_all
        end
      end

      desc "#{namespace}:revision", "Shows the site status"
      def revision
        prepare :revision
        boot!
        say "Site is at revision #{::Site.revision}", :green
      end

      desc "#{namespace}:browse", "Launces a browser pointing to the current development CMS"
      def browse
        prepare :browse
        require 'launchy'
        boot!
        ::Launchy::Browser.run("http://localhost:#{::Site.config.port}/@spontaneous")
      end
    end
  end
end
