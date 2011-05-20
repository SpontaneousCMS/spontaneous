# encoding: UTF-8

module Spontaneous::Plugins
  module Styles

    def self.configure(base)
    end

    module ClassMethods
      def style(name, options={})
        styles << Spontaneous::Style.new(style_directory_name, name, options)
      end

      def styles
        @inline_styles ||= []
      end

      def resolve_style(format, style_id)
        if style_id.blank?
          default_style(format)
        else
          find_named_style(format, style_id)
        end
      end

      def default_style(format = :html)
        if styles.empty?
          style = Spontaneous::Style.new(nil, style_directory_name)
          if S::Render.exists?(style.template, format)
            style
          else
            if supertype_has_styles?
              supertype.default_style(format)
            else
              nil
            end
          end
        else
          styles.detect { |s| s.default? } or styles.first
        end
      end

      def find_named_style(format, style_id)
        name = style_id.to_sym
        unless style = styles.detect { |s| s.name == name }
          # style = supertype.resolve_style(name) if supertype_has_style?
        end
        style
      end

      # def template(format=:html, erb_code=nil)
      #   if erb_code.nil?
      #     erb_code = format
      #     format = :html
      #   end
      #   inline_templates[format.to_sym] = eval(%(Proc.new { #{erb_code.inspect} }))
      # end

      # def inline_templates
      #   @inline_templates ||= {}
      # end

      # Used to determine the name of the directory under template_root
      # that holds a classe's templates
      def style_directory_name
        self.name.demodulize.underscore
      end

      # don't want to go right back to Content class to resolve default styles
      def supertype_has_styles?
        supertype? and supertype != Spontaneous::Content
      end
    end # ClassMethods

    module InstanceMethods

      def style=(style_id)
        self.style_id = style_id
      end

      def style(format = :html)
        resolve_style(format, self.style_id)
      end

      def resolve_style(format, style_id)
        self.class.resolve_style(format, style_id)
      end

      def template(format = :html)
        style(format).template(format)
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


    # Used by slots to check for the existance of a template named
    # SlotsOwningClass.template_directory/slot_name.{format}.erb
    # and use it if it exists
    # if not it falls back to a default template that just renders the
    # Piece's content
    class AnonymousStyle
      def initialize(container, label)
        @container = container
        @label = label
      end

      def template(format=:html)
        if has_default_template?(format)
          style.template(format)
        else
          lambda { '{{ render_content }}' }
        end
      end

      def has_default_template?(format)
        return false if @label.nil? or @label.empty?
        Spontaneous::Render.exists?(Spontaneous::Render.template_root, style.path, format)
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

    def path(format=:html)
      owner_directory_name
    end

    def name
      owner_directory_name
    end


    def default?
      true
    end

    def basename
      owner_directory_name
    end

    def owner_directory_name
      (@owner.name || "").underscore
    end

    def title
      "#{owner.name} Default"
    end
  end
end

