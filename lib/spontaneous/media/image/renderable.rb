
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

    alias_method :render_inline, :render

    DEFAULT_SIZE_FLAGS = ['auto'.freeze, :auto, true].freeze

    def to_html(opts={})
      default_attr = { src: src, alt: "" }
      attrs = Spontaneous::Field::Image.default_attributes.merge(opts)

      if template_params && template_params.length > 0 && template_params[0].is_a?(Hash)
        attrs = template_params[0].merge(attrs)
      end

      case attrs.delete(:size)
      when true, :auto, 'auto'
        attrs[:width] = width if has_width?
        attrs[:height] = height if has_height?
      end

      if attrs.key?(:width) || attrs.key?(:height)
        attrs.delete(:width)  if (attrs.key?(:width) && !attrs[:width])
        attrs.delete(:height) if (attrs.key?(:height) && !attrs[:height])
        if has_width? && DEFAULT_SIZE_FLAGS.include?(attrs[:width])
          attrs[:width] = width
        end
        if has_height? && DEFAULT_SIZE_FLAGS.include?(attrs[:height])
          attrs[:height] = height
        end
      end

      attrs = default_attr.merge(attrs)
      params = parameterize_attributes(attrs)
      %(<img #{params} />)
    end

    def parameterize_attributes(attrs, namespace = [])
      params = []
      attrs.each do |name, value|
        key = (namespace + [name])
        v = case value
        when Hash
          parameterize_attributes(value, key)
        when Proc
          %(#{key.join('-')}="#{value.call(self).to_s.escape_html}")
        else
          %(#{key.join('-')}="#{value.to_s.escape_html}")
        end
        params << v
      end
      params.join(' ')
    end

    def has_height?
      has_dim?(height)
    end

    def has_width?
      has_dim?(width)
    end

    def has_dim?(dim)
      !(dim.nil? || dim == 0)
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
