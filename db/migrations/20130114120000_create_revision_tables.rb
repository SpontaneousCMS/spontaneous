
require 'logger'
require 'spontaneous'
require 'benchmark'

Sequel.migration do
  ContentTable = S::DataMapper::ContentTable
  revision_table = :spontaneous_content_revisions
  archive_table  = :spontaneous_content_archive
  content_table  = :content

  keep_revisions = 10

  logger = ::Logger.new($stdout)

  up do

    add_column content_table, :revision, :integer, :default => nil

    state = self[:spontaneous_state].first

    current_revision = state.nil? ? 0 : state[:published_revision]

    [revision_table, archive_table].each do |table|
      drop_table?(table)
      run %(CREATE TABLE #{literal(table)} AS (SELECT * FROM #{literal(content_table)} LIMIT 1);)
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

      self.logger = nil

      revisions.each do |(table, revision)|
        begin
          print ">> Copying revision #{revision} from table #{table} ... "
          bm = Benchmark.measure do
            transaction do
              dest = archive_table
              dest = revision_table if revision > keep_revision
              run <<-SQL
                INSERT #{literal(dest)} (#{insert_columns})
                SELECT #{select_columns}, #{revision}
                FROM #{literal(table)}
              SQL
              drop_table table unless revision == current_revision
            end
          end
          puts " done (#{"%.4f" % bm.real}s)"
        rescue Sequel::DatabaseError => e
          logger.error(e.message)
        end
      end

      self.logger = logger

      # Dont want an index on the archive because the assumption is that we won't
      # need it except for archival purposes and the index will add space & slow
      # things down.
      add_index revision_table, :revision

      # Because of errors some of the revisions will have been left.
      # Just delete them.
      current_revision_table = ContentTable.revision_table(content_table, current_revision)
      drop_tables = self.tables.
        select { |t| ContentTable.revision_table?(content_table, t) }.
        reject { |t| t == current_revision_table }

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

