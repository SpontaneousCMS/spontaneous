# encoding: UTF-8

module Spontaneous
  module Extensions
    module Class
      def ui_class
        name.gsub(/::/, ".")
      end
    end
  end
end


class Class
  include Spontaneous::Extensions::Class
end

