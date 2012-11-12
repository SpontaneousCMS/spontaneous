# encoding: UTF-8

require 'forwardable'

module Spontaneous::Search
  # Wraps XapianFu::ResultSet to provide a list of pages rather than a list of
  # XapianDocs
  class Results
    extend  Forwardable
    include Enumerable

    def_delegators :@results, :current_page, :per_page, :total_pages, :next_page, :offset, :previous_page, :total_entries

    def initialize(result_set, corrected_query = nil)
      @results, @corrected_query = result_set, corrected_query
    end

    def corrected_query
      @corrected_query || @results.corrected_query
    end

    def each
      pages.each { |page| yield(page) }
    end

    def length
      pages.length
    end

    def pages
      @page_list ||= @results.map { |doc| ::Content.first(:id => doc.id) }
    end
  end # Results
end
