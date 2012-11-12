# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Level
    extend Spontaneous::Concern

    module ClassMethods
      def at_depth(level)
        case level
        when 0, :root
          Spontaneous::Site.root
        when 1, :section
          Spontaneous::Site.root.at_depth(1)
        end
      end
    end # ClassMethods
  end # Level
end
