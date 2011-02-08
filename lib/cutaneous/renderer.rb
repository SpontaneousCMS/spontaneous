# encoding: UTF-8

module Cutaneous
  class Renderer# < Spontaneous::Renderer
    attr_reader :template_root

    def initialize(template_root)
      @template_root = template_root
    end

    def extension
      Cutaneous.extension
    end

    def render_string(string, content, format = :html, params = {})
      template = string_to_template(string)
      render_template(template, content, format, params)
    end

    def render_file(file_path, content, format = :html, params = {})
      template = get_template(file_path, format)
      render_template(template, content, format, params)
    end

    # protected

    def render_template(template, content, format, params = {})
      context = context_class.new(content, format, params)
      render(template, context)
    end


    def create_template(filepath, format)
      template_class.new(filepath, format)
    end

    def get_template(template_or_filepath, format)
      case template_or_filepath
      when String
        filepath = Spontaneous::Render.template_file(template_root, template_or_filepath, format)
        create_template(filepath, format)
      when Proc
        create_template(template_or_filepath, format)
      else
        template_or_filepath
      end
    end

    def string_to_template(string)
      template = template_class.new
      template.convert(string)
      template
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



