# encoding: UTF-8

module Spontaneous::Cli
  class Migrate < ::Thor
    include Spontaneous::Cli::TaskUtils
    include Thor::Actions

    namespace    :migrate
    default_task :apply

    desc :apply, "Runs Spontaneous migrations"
    def apply
      prepare! :migrate
      Sequel.extension :migration
      say "  >> Running migrations..."
      Sequel::Migrator.apply(Spontaneous.database, ::Spontaneous.gem_dir('db/migrations'))
      say "  >> Done"
    end
  end # Migrate
end # Spontaneous::Cli
