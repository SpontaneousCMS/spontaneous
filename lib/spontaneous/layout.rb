# encoding: UTF-8

module Spontaneous
  class Layout < Style
    def try_templates
      [["layouts", prototype.name.to_s]]
    end

    class Default < Layout
      def try_templates
        [["layouts", "standard"]]
      end
    end
  end
end
