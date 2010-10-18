
module Spontaneous
  module Extensions
    module String
      def /(path)
        File.join(self, path.to_s)
      end
    end
  end
end


class String
  include Spontaneous::Extensions::String
end
