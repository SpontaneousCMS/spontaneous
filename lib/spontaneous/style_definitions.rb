
module Spontaneous
  class StyleDefinitions < Array
    # attr_reader :owner

    # def initialize(owner)
    #   super
    #   @owner = owner
    # end

    def [](index)
      case index
      when nil
        default
      when Symbol, String
        inject({}) { |h, s| h[s.name] = s; h }[index.to_sym]
      else
        super
      end
    end

    def default
      find { |s| s.default? } || first
    end

  end
end
