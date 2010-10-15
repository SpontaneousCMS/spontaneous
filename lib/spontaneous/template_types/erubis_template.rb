module Spontaneous
  module TemplateTypes
    class ErubisTemplate < Template
      def render(binding)
        template.result(binding).chomp
      end

      def template
        @template ||= Erubis::Eruby.new(source)
      end

      def source
        File.read(path)
      end
    end
  end
end

