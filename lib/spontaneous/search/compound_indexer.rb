# encoding: UTF-8


module Spontaneous::Search
  class CompoundIndexer
    def initialize(revision, indexes)
      @revision, @indexes, @dbs = revision, indexes, indexes.map { |index| index.create_db(revision) }
    end

    def add(page)
      @dbs.each { |db| db << page }
    end

    alias_method :<<, :add

    def close
      @dbs.each { |db| db.close }
    end
  end # CompoundIndexer
end
