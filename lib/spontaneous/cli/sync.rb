
module Spontaneous
  module Cli
    class Sync < ::Spontaneous::Cli::Thor
      Spontaneous = ::Spontaneous
      namespace :sync
      default_task :down

      class SyncTask < ::Thor::Group
        protected

        def arse(n)
          puts 'arse '+n
        end
      end

      class Down < SyncTask
        desc "Syncs down"
        def one
          arse('one')
        end
        def two
          arse('two')
        end
      end

      class Up < SyncTask
        desc "Syncs up"
      end

      desc "#{namespace}:down", "Makes the local copy a clone of the live server"
      def down
        Down.start
      end

      desc "#{namespace}:up", "Makes the local copy a clone of the live server"
      def up
        Down.start
      end
    end
  end
end
