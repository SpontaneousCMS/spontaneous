# encoding: UTF-8

module Spontaneous::Extensions
  module NilClass
    def or(alternative)
      alternative
    end

    alias_method :/, :or
  end # String
end # Extensions

class NilClass
  include Spontaneous::Extensions::NilClass
end
