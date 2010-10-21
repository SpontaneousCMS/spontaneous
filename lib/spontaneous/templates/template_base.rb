
module Spontaneous
  module Templates
    class TemplateBase
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def compiled_template
        Templates.cached(path) do
          self.compile
        end
      end

      def filename
        File.basename(@path)
      end

      def render(binding)
        #should be over-ridden by implementations
      end

      def compile
        #should be over-ridden by implementations
      end
    end
  end
end
