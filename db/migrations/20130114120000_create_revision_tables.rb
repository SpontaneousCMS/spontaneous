
require 'logger'
require 'spontaneous'

Sequel.migration do
  ContentTable = S::DataMapper::ContentTable
  revision_table = :spontaneous_content_revisions
  archive_table  = :spontaneous_content_archive
  content_table  = :content

  keep_revisions = 10

  logger = ::Logger.new($stdout)

  up do
    self.logger = logger

    add_column content_table, :revision, :integer, :default => nil

    current_revision = self[:spontaneous_state].first[:published_revision]

    [revision_table, archive_table].each do |table|
      run %(CREATE TABLE #{literal(table)} AS (SELECT * FROM #{literal(content_table)} LIMIT 1);)
      self[table].delete
    end


    tables = self.tables
    revisions = tables.select { |t| ContentTable.revision_table?(content_table, t)}.sort

    revisions = revisions.map { |name| [name, ContentTable.revision_number(content_table, name)] }

    unless revisions.empty?

      max_revision = revisions.map { |(table, revision)| revision }.max


      keep_revision = max_revision - keep_revisions

      columns = self[content_table].columns.
        reject { |c| c == :revision }.
        map { |c| literal(c)}

      insert_columns = (columns + [literal(:revision)]).join(", ")
      select_columns = columns.join(", ")

      revisions.each do |(table, revision)|
        begin
          dest = archive_table
          dest = revision_table if revision > keep_revision
          run <<-SQL
          INSERT #{literal(dest)} (#{insert_columns})
            SELECT #{select_columns}, #{revision}
            FROM #{literal(table)}
            SQL
            drop_table table unless revision == current_revision
        rescue Sequel::DatabaseError => e
          logger.error(e.message)
        end
      end

      # Dont want an index on the archive because the assumption is that we won't
      # need it except for archival purposes and the index will add space & slow
      # things down.
      add_index revision_table, :revision

      # Because of errors, some of the revisions will have been left.
      # Just delete them.
      max_revision_table = ContentTable.revision_table(content_table, max_revision)
      drop_tables = self.tables.
        select { |t| ContentTable.revision_table?(content_table, t) }.
        reject { |t| t == max_revision_table }

      drop_tables.each do |table|
        drop_table table
      end
    end
    self.logger = nil
  end

  down do
    # Not going to do a full down implementation until I need to
    # If things have gone wrong then all is lost anyway, and I won't be able
    # to recover the lost revision data.
    # If all is well then recovering the revision tables from the archives
    # is trivial (but dull).
    [revision_table, archive_table].each do |table|
      drop_table table
    end

    drop_column content_table, :revision
  end
end

