module Spontaneous
  module Templates
    class ErubisTemplate < TemplateBase
      def render(binding)
        compiled_template.result(binding).chomp
      end

      def compile
        Erubis::Eruby.new(source)
      end

      def source
        File.read(path)
      end
    end
  end
end

