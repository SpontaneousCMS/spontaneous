
module Spontaneous
  module Cli
    class Media < ::Thor
      namespace :media

      desc "cleanup", "Removes stale temp files"
      def cleanup
        puts "CLEANING UP!!"
      end
    end
  end
end
