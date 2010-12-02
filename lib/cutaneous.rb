require "tenjin"

module Cutaneous
  def self.template_path(filename, format)
    Spontaneous.template_path(template_name(filename, format))
  end
  def self.template_name(filename, format)
    "#{filename}.#{format}.#{self.extension}"
  end
  def self.extension
    'cut'
  end

  autoload :ContextHelper, "cutaneous/context_helper"
  autoload :PreviewContext, "cutaneous/preview_context"
  autoload :PublishContext, "cutaneous/publish_context"
  autoload :RequestContext, "cutaneous/request_context"
  autoload :TemplateCore, "cutaneous/template_core"
  autoload :Template, "cutaneous/template"
  autoload :Preprocessor, "cutaneous/preprocessor"
  autoload :RenderEngine, "cutaneous/render_engine"
  autoload :FirstRenderEngine, "cutaneous/first_render_engine"
  autoload :SecondRenderEngine, "cutaneous/second_render_engine"
  autoload :PreviewRenderEngine, "cutaneous/preview_render_engine"
  autoload :PublishRenderEngine, "cutaneous/publish_render_engine"
end
