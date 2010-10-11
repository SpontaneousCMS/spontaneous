
module Spontaneous
  class StyleSet < Array
    def [](index)
      case index
      when Symbol
        inject({}) { |h, s| h[s.name] = s; h }[index]
      else
        super
      end
    end
  end
end
