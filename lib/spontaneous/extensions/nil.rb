# encoding: UTF-8

module Spontaneous::Extensions
  module NilClass
    def /(alternative)
      alternative
    end
  end # String
end # Extensions

class NilClass
  include Spontaneous::Extensions::NilClass
end
