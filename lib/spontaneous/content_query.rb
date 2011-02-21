# encoding: UTF-8

module Spontaneous
  class ContentQuery
    ALL = "*".freeze

    def initialize(selector)
      @selector = selector
    end

    def matches(content)
      return true if @selector == ALL
    end
    alias_method :matches?, :matches
  end
end

