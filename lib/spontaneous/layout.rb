# encoding: UTF-8

module Spontaneous
  class Layout < Style
    def try_paths
      [["layouts", prototype.name.to_s]]
    end

    class Default < Layout
      def try_paths
        [["layouts", "standard"]]
      end
    end
  end
end
