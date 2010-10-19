
module Spontaneous
  class Site <  Sequel::Model(:sites)
    class << self
      def map(root_id=nil)
        if root_id.nil?
          Page.root.map_entry
        else
          Content[root_id].map_children
        end
      end
    end
  end
end
