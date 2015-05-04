module Spontaneous::Publishing::Steps
  class GenerateSearchIndexes < BaseStep

    def call
      return if indexes.empty?
      progress.stage("indexing")
      site.indexer(revision) do |indexer|
        site.pages.each do |page|
          indexer << page
          progress.step(1, page.path.inspect)
        end
      end
    end

    def count
      return 0 if indexes.empty?
      site.pages.count
    end

    def indexes
      site.indexes
    end
  end
end
