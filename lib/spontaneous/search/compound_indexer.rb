# encoding: UTF-8


module Spontaneous::Search
  class CompoundIndexer
    def initialize(revision, indexes)
      @revision, @indexes, @dbs = revision, indexes, indexes.map { |index| index.create_db(revision) }
    end

    def length
      @indexes.length
    end
    alias_method :count, :length
    alias_method :size,  :length

    def add(page)
      @dbs.each { |db| db << page }
    end

    alias_method :<<, :add

    def close
      @dbs.each { |db| db.close }
    end
  end # CompoundIndexer
end
