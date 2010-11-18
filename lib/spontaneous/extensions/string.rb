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

      HTML_ESCAPE_TABLE = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;',
        "'" => '&#039;',
      }

      def escape_html
        self.gsub(%r{[#{HTML_ESCAPE_TABLE.keys.join}]}) { |s| HTML_ESCAPE_TABLE[s] }
      end
    end
  end
end


class String
  include Spontaneous::Extensions::String
end
