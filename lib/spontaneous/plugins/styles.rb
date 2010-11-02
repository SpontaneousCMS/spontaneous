# encoding: UTF-8

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
      def template_class
        self.class
      end

      def styles
        self.class.inline_styles
      end

      def style
        self.class.inline_styles[style_id] || default_style || anonymous_style
      end

      def template(format=:html)
        style.template(format)
      end

      def anonymous_style
        @anonymous_style ||= \
          unless self.class.inline_templates.empty?
            InlineStyle.new(self)
          else
            AnonymousStyle.new(container, label)
          end
      end

      def default_style
        @default_style ||= DefaultStyle.new(self.template_class)
        return nil if @default_style.formats.empty?
        @default_style
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

      def render(context)
        context.instance_eval("\"#{@source}\"")
      end
      def path
        "<InlineTemplate>"
      end
    end

    # Used by slots to check for the existance of a template named
    # SlotsOwningClass.template_directory/slot_name.{format}.erb
    # and use it if it exists
    # if not it falls back to a default template that just renders the 
    # Facet's content
    class AnonymousStyle
      def initialize(container, label)
        @container = container
        @label = label
      end

      def template(format=:html)
        if has_default_template?(format)
          style.template(format)
        else
          self
        end
      end

      def has_default_template?(format)
        return false if @label.nil? or @label.empty?
        File.exists?(style.path(format))
      end

      def style
        @style ||= Spontaneous::Style.new(@container.class, @label)
      end

      def render(context)
        context.instance_eval('render_content')
      end

      def path
        "<Anonymous>"
      end
    end # AnonymousStyle
  end

  class DefaultStyle < Spontaneous::Style
    def initialize(owner)
      @owner = owner
    end

    def name
      owner_directory_name
    end

    def directory
      Spontaneous.template_root
    end

    def default?
      true
    end

    def basename
      owner_directory_name
    end

    def owner_directory_name
      @owner.name.underscore
    end

    def title
      "#{owner.name} Default"
    end
  end
end

