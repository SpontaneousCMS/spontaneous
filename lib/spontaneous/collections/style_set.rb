# encoding: UTF-8

module Spontaneous::Collections
  class StyleSet < PrototypeSet

    attr_reader :owner

    def initialize(owner)
      super(owner.supertype, :style_prototypes)
      @owner = owner
    end

    def default

    end

  end # StyleSet
end # Spontaneous::Collections
