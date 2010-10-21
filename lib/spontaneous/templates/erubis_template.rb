module Spontaneous
  module Templates
    class ErubisTemplate < TemplateBase
      def render(context)
        compiled_template.evaluate(context).chomp
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

