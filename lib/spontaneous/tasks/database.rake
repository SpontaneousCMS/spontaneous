
namespace :spot do
  desc "Migrate the core Spontaneous database"
  task :migrate do
    Spontaneous.database.logger = Spontaneous.logger
    Sequel.extension :migration
    Sequel::Migrator.apply(Spontaneous.database, Spontaneous.gem_dir('db/migrations'))
  end
end

namespace :db do
  desc "Make a dump of the current database"
  task :dump do
    dumper = Spontaneous::Utils::Database.dumper_for_database
    dumpfilename = ENV['dumpfile'] || dumper.dumpfilename
    dumpfile = "tmp/#{dumpfilename}"
    dumper.dump(dumpfile)
  end

  desc "Load a database dump into the local database"
  task :load do
    dumpfile = ENV['dumpfile']
    dumper = Spontaneous::Utils::Database.dumper_for_database
    if dumpfile.nil?
      $stderr.puts "Usage: rake spot:database:load dumpfile=/path/to/dump.#{dumper.name}.gz"
      exit 1
    end
    dumper.load(dumpfile)
  end
end
