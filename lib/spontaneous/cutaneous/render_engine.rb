module Spontaneous::Cutaneous
  class RenderEngine

    def template_class
      # override in subclasses
    end

    def find_template_file(filename, format)
      Spontaneous::Cutaneous.template_path(filename, format)
    end

    def create_template(filepath, format)
      template_class.new(filepath, format)
    end

    def get_template(filename, format)
      # insert caching here
      filepath = find_template_file(filename, format)
      template = create_template(filepath, format)
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
          puts layout
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


