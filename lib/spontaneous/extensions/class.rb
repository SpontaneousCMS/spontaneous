module Spontaneous
  module Extensions
    module Class
      def json_name
        name.gsub(/::/, ".")
      end
    end
  end
end


class Class
  include Spontaneous::Extensions::Class
end

