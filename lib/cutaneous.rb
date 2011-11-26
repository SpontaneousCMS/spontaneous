
module Cutaneous
  def self.template_path(filename, format)
    Spontaneous.template_path(template_name(filename, format))
  end

  def self.template_name(filename, format)
    "#{filename}.#{format}.#{self.extension}"
  end

  # this is basicially the API that any templating engine has to provide
  def self.extension
    'cut'
  end

  def self.preview_renderer
    PreviewRenderer
  end

  def self.publishing_renderer
    PublishRenderer
  end

  def self.request_renderer
    RequestRenderer
  end

  def self.is_dynamic?(render)
    RequestTokenParser.is_dynamic?(render)
  end


  autoload :ContextHelper, "cutaneous/context_helper"
  autoload :PreviewContext, "cutaneous/preview_context"
  autoload :PublishContext, "cutaneous/publish_context"
  autoload :RequestContext, "cutaneous/request_context"

  autoload :Renderer, "cutaneous/renderer"
  autoload :PublishRenderer, "cutaneous/publish_renderer"
  autoload :RequestRenderer, "cutaneous/request_renderer"
  autoload :PreviewRenderer, "cutaneous/preview_renderer"

  autoload :TokenParser, "cutaneous/token_parser"
  autoload :PublishTokenParser, "cutaneous/publish_token_parser"
  autoload :RequestTokenParser, "cutaneous/request_token_parser"
  autoload :PublishTemplate, "cutaneous/publish_template"
  autoload :RequestTemplate, "cutaneous/request_template"
end
