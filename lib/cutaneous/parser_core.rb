# encoding: UTF-8

module Cutaneous
  module ParserCore
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    def initialize(filepath=nil, format=:html)
      @format = format
      super(filepath)
    end
  end
end

