module Spontaneous::Plugins
  module Styles

    def self.configure(base)
      base.instance_eval do
        class << self
          alias_method :styles, :inline_styles
        end
      end
    end

    module ClassMethods
      def inline_style(name, options={})
        inline_styles << Spontaneous::Style.new(self, name, options)
      end

      def inline_styles
        @inline_styles ||= Spontaneous::StyleDefinitions.new
      end

      def template(format=:html, erb_code=nil)
        if erb_code.nil?
          erb_code = format
          format = :html
        end
        inline_templates[format.to_sym] = InlineTemplate.new(erb_code)
      end

      def inline_templates
        @inline_templates ||= {}
      end
    end # ClassMethods

    module InstanceMethods
      def styles
        self.class.inline_styles
      end

      def style
        self.class.inline_styles[style_id] or anonymous_style
      end

      def template(format=:html)
        style.template(format)
      end

      def anonymous_style
        @anonymous_style ||= \
          unless self.class.inline_templates.empty?
            InlineStyle.new(self)
          else
            AnonymousStyle.new
          end
      end
    end # InstanceMethods

    class InlineStyle
      def initialize(target)
        @target = target
      end

      def template(format=:html)
        @target.class.inline_templates[format.to_sym]
      end
    end # InlineStyle

    class InlineTemplate
      def initialize(source)
        @source = source
      end

      def render(binding)
        eval("\"#{@source}\"", binding)
      end
    end
    # class InlineTemplate < Spontaneous::TemplateTypes::ErubisTemplate
    #   attr_reader :source

    #   def initialize(source)
    #     @source = source
    #   end
    # end # InlineTemplate

    class AnonymousStyle
      def template(format=:html)
        self
      end

      def render(binding)
        eval('render_content', binding)
      end
    end # AnonymousStyle
  end
end

