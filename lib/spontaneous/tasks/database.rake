require 'spontaneous/cli/site'

namespace :spot do
  desc "Migrate the core Spontaneous database"
  task :migrate do
    Spontaneous.database.logger = Spontaneous.logger
    Sequel.extension :migration
    Sequel::Migrator.apply(Spontaneous.database, Spontaneous.gem_dir('db/migrations'))
  end


  namespace :database do
    desc "Make a dump of the current database"
    task :dump do
      dumpfilename = ENV['dumpfile']
      if dumpfilename.nil?
        dumpfilename = "#{Time.now.to_i}.mysql.gz"
      end
      dump_file = "tmp/#{dumpfilename}"
      dumper = Spontaneous::Cli::Site::MySQL.new(Spontaneous.database)
      dumper.dump(dump_file)
    end
  end
end
