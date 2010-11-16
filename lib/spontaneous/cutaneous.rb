
module Spontaneous
  module Cutaneous
    def self.template_path(filename, format)
      Spontaneous.template_path("#{filename}.#{format}.#{self.extension}")
    end
    def self.extension
      'cut'
    end

    autoload :ContextHelper, "spontaneous/cutaneous/context_helper"
    autoload :TemplateCore, "spontaneous/cutaneous/template_core"
    autoload :Template, "spontaneous/cutaneous/template"
    autoload :Preprocessor, "spontaneous/cutaneous/preprocessor"
    autoload :RenderEngine, "spontaneous/cutaneous/render_engine"
    autoload :FirstRenderEngine, "spontaneous/cutaneous/first_render_engine"
    autoload :SecondRenderEngine, "spontaneous/cutaneous/second_render_engine"
  end
end
