# encoding: UTF-8

class Spontaneous::Site
  module Level
    extend Spontaneous::Concern

    def at_depth(level)
      case level
      when 0, :root, :home
        home
      when 1, :section
        home.at_depth(1)
      end
    end
  end # Level
end
