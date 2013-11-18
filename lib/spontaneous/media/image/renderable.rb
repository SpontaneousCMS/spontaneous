
module Spontaneous::Media::Image
  module Renderable
    attr_accessor :template_params

    def render(format=:html, params = {}, parent_context = nil)
      case format
      when "html", :html
        to_html(params)
      else
        value
      end
    end

    def to_html(attr={})
      default_attr = {
        :src => src,
        :width => width,
        :height => height,
        :alt => ""
      }
      default_attr.delete(:width) if (width.nil? || width == 0)
      default_attr.delete(:height) if (height.nil? || height == 0)
      if template_params && template_params.length > 0 && template_params[0].is_a?(Hash)
        attr = template_params[0].merge(attr)
      end
      if attr.key?(:width) || attr.key?(:height)
        default_attr.delete(:width)
        default_attr.delete(:height)
        if (attr.key?(:width) && !attr[:width]) || (attr.key?(:height) && !attr[:height])
          attr.delete(:width)
          attr.delete(:height)
        end
      end
      attr = default_attr.merge(attr)
      params = []
      attr.each do |name, value|
        params << %(#{name}="#{value.to_s.escape_html}")
      end
      %(<img #{params.join(' ')} />)
    end

    def to_s
      src
    end

    def /(value)
      return value if self.blank?
      self
    end
  end
end
