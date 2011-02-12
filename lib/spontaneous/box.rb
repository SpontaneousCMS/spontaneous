# encoding: UTF-8

module Spontaneous
  class Box
    attr_reader :name

    def initialize(name, owner)
      @name, @owner = name, owner
    end
  end
end
