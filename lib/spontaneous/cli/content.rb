module Spontaneous
  module Cli
    class Content < ::Thor
      include Spontaneous::Cli::TaskUtils

      namespace :content

      desc "clean", "Cleans up the content after schema migration(s) by deleting instances belonging to deleted types and their children"

      def clean(*args)
        clean_content
      end

      protected

      def clean_content
        prepare!(:clean)
        say "==> Cleaning content table..."
        say ""
        result = Spontaneous::Model::Action::Clean.run(Spontaneous::instance)
        say "----> Deleted ", :bold
        say "#{result[:invalid]} ", [:red, :bold]
        say "entries with invalid schema types"
        say "----> Deleted ", :bold
        say "#{result[:orphans]} ", [:red, :bold]
        say "orphaned entries"
        say "----> Deleted ", :bold
        say "#{result[:unlinked]} ", [:red, :bold]
        say "unlinked content (belonging to non-existant box)"
        say ""
        if result[:publish]
          say("====> Site is configured to force a full publish", [:red, :bold])
          say ""
        end
      end
    end
  end
end
