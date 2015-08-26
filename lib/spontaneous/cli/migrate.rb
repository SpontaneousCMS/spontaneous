# encoding: UTF-8

module Spontaneous::Cli
  class Migrate < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace    :migrate
    default_task :apply

    desc :apply, "Runs Spontaneous migrations"
    def apply
      site = prepare! :migrate
      Sequel.extension :migration
      run_migrations(::Spontaneous.gem_dir, "Running Spontaneous migrations...")
      run_migrations(site.root, "Running site migrations...", table: :schema_migrations_site)
    end

    protected

    def run_migrations(dir, msg, opts = {})
      migration_dir = ::File.join(dir, 'db/migrations')
      if ::File.directory?(migration_dir)
        say "  >> #{msg}"
        Sequel::Migrator.run(Spontaneous.database, migration_dir, opts)
        say "  >> Done"
      end
    end
  end # Migrate
end # Spontaneous::Cli
