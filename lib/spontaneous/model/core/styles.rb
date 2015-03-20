# encoding: UTF-8

module Spontaneous::Model::Core
  module Styles
    extend Spontaneous::Concern

    module ClassMethods
      def style(name, options={})
        name = name.to_sym
        styles[name] = Spontaneous::Prototypes::StylePrototype.new(self, name, options)
      end

      def style_prototypes
        @style_prototypes ||= Spontaneous::Collections::StyleSet.new(self)
      end

      alias_method :styles, :style_prototypes

      def resolve_style(style_sid)
        if style_sid.blank?
          default_style
        else
          find_style(style_sid)
        end
      end

      def default_style
        if styles.empty?
          style = style_class::Default.new(self)
        else
          style = (style_prototypes.detect { |prototype| prototype.default? } || style_prototypes.first).style(self)
        end
      end

      def style_class
        Spontaneous::Style
      end

      def find_style(style_sid)
        if prototype = style_prototypes.sid(style_sid)
          prototype.style(self)
        end
      end

      def find_named_style(style_name)
        style_prototypes[style_name.to_sym]
      end

      alias_method :get_style, :find_named_style

      def template(format=:html, template_string=nil)
        if template_string.nil?
          template_string = format
          format = :html
        end
        inline_templates[format.to_sym] = template_string
      end

      def inline_templates
        @inline_templates ||= {}
      end
    end # ClassMethods

    # InstanceMethods

    def style=(style)
      self.style_sid = style_to_schema_id(style).to_s
    end

    # converts a symbol or string into a Schema::UID instance
    def style_to_schema_id(style)
      return nil if style.nil?
      sid = nil
      if style.respond_to?(:schema_id)
        sid = style.schema_id
      else
        if Spontaneous::Schema::UID === style
          sid = style
        else
          if s = self.find_named_style(style)
            sid = s.schema_id
          end
        end
      end
    end

    def find_named_style(style_name)
      self.class.find_named_style(style_name)
    end

    def style
      resolve_style(style_sid)
    end

    def default_style
      self.class.default_style
    end

    def resolve_style(style_sid)
      self.class.resolve_style(style_sid)
    end

    def styles
      self.class.styles
    end

    def template(format = :html, renderer = Spontaneous::Output.default_renderer)
      style.template(format, renderer)
    end
  end
end
