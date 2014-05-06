# encoding: UTF-8

class Spontaneous::Site
  module Search
    extend Spontaneous::Concern

    def indexer(revision)
      indexer = S::Search::CompoundIndexer.new(revision, indexes.values)
      begin
        yield(indexer)
      ensure
        indexer.close
      end
    end

    def indexes
      @indexes ||= {}
    end

    def [](name)
      indexes[name.to_sym]
    end

    def []=(name, index)
      indexes[name.to_sym] = index
    end

    def index(name, &definition)
      index = S::Search::Index.new(self, name, &definition)
      self[name] = index
    end
  end
end
