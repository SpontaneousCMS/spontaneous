# encoding: UTF-8


module Spontaneous
  module Extensions
    module String
      def /(path)
        File.join(self, path.to_s)
      end

      def json
        Yajl::Parser.new(:symbolize_keys => true).parse(self)
      end
    end
  end
end


class String
  include Spontaneous::Extensions::String
end
