# encoding: UTF-8

module Spontaneous
  module Search
    autoload :Index,    'spontaneous/search/index'
    autoload :Field,    'spontaneous/search/field'
    autoload :Database, 'spontaneous/search/database'
    autoload :Results,  'spontaneous/search/results'
    autoload :CompoundIndexer, 'spontaneous/search/compound_indexer'
  end
end
