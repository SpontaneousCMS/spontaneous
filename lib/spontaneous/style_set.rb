
module Spontaneous
  class StyleSet < Array
    # attr_reader :owner

    # def initialize(owner)
    #   super
    #   @owner = owner
    # end

    def [](index)
      case index
      when Symbol
        inject({}) { |h, s| h[s.name] = s; h }[index]
      else
        super
      end
    end

    def default
      find { |s| s.default? } || first
    end

  end
end
