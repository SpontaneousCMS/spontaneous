# encoding: UTF-8

module Spontaneous
  class Box
    attr_reader :name

    attr_reader :prototype

    def initialize(name, prototype, owner)
      @name, @prototype, @owner = name, prototype, owner
    end

    def box_name
      prototype.name
    end
  end
end
