
namespace :spot do
  desc "Migrate the core Spontaneous database"
  task :migrate do
    Spontaneous.database.logger = Spontaneous.logger
    Sequel.extension :migration
    Sequel::Migrator.apply(Spontaneous.database, Spontaneous.gem_dir('db/migrations'))
  end
end
