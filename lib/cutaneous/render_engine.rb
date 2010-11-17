module Cutaneous
  class RenderEngine

    def initialize(template_root)
      @template_root = File.expand_path(template_root)
    end

    def extension
      Cutaneous.extension
    end

    def template_class
      # override in subclasses
    end

    def template_file(filename, format)
      File.join(@template_root, Cutaneous.template_name(filename, format))
    end

    def template_path(filename)
      File.join(@template_root, filename)
    end

    def create_template(filepath, format)
      template_class.new(filepath, format)
    end

    def get_template(filename, format)
      if filename.is_a?(Proc)
        template = create_template(filename, format)
      else
        # insert caching here
        filepath = template_file(filename, format)
        template = create_template(filepath, format)
      end
    end

    def render(filename, context, _layout=true)
      hook_context(context)
      while true
        template = get_template(filename, context.format)
        _buf = context._buf
        output = template.render(context)
        context._buf = _buf
        unless context._layout.nil?
          layout = context._layout
          context._layout = nil
        end
        break unless layout
        filename = layout
        layout = false
      end
      output
    end

    def hook_context(context)
      context._engine = self
      context._layout = nil
      context
    end
  end
end


