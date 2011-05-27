# encoding: UTF-8

module Spontaneous::Plugins
  module Styles

    def self.configure(base)
    end

    module ClassMethods
      def style(name, options={})
        s = Spontaneous::Style.new(self, style_directory_name, name, options.merge(:style_id => name))
        styles << s
        s
      end

      def styles
        @styles ||= []
      end

      def all_styles
        styles.concat(supertype_has_styles? ? supertype.all_styles : [])
      end

      def resolve_style(style_id, format = :html)
        if style_id.blank?
          default_style(format)
        else
          find_named_style(style_id, format)
        end
      end

      def default_style(format = :html)
        if template_string = inline_templates[format.to_sym]
          Spontaneous::Style::Anonymous.new(template_string)
        else
          if styles.empty?
            style = Spontaneous::Style.new(self, nil, style_directory_name)
            if style.exists?(format)
              style
            else
              if supertype_has_styles?
                supertype.default_style(format)
              else
                # this is the case where no template file can be found
                anonymous_style
              end
            end
          else
            usable_styles = styles_for_format(format)
            usable_styles.detect { |s| s.default? } or usable_styles.first
          end
        end
      end

      def styles_for_format(format)
        styles.select { |s| s.exists?(format) }
      end

      def anonymous_style
        Spontaneous::Style::Anonymous.new
      end

      def find_named_style(style_id, format = :html)
        name = style_id.to_sym
        unless style = styles.detect { |s| s.name == name }
          style = supertype.resolve_style(name) if supertype_has_styles?
        end
        style
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

      # Used to determine the name of the directory under template_root
      # that holds a classe's templates
      def style_directory_name
        return nil if self.name.blank?
        self.name.demodulize.underscore
      end

      # don't want to go right back to Content class to resolve default styles
      def supertype_has_styles?
        supertype? and supertype != Spontaneous::Content
      end
    end # ClassMethods

    module InstanceMethods

      def style=(style)
        style = style.style_id if style.respond_to?(:style_id)
        self.style_id = style
      end

      def style(format = :html)
        resolve_style(self.style_id, format)
      end

      def default_style(format = :html)
        self.class.default_style(format)
      end

      def resolve_style(style_id, format = :html)
        self.class.resolve_style(style_id, format)
      end

      def styles
        @_styles ||= Hash[self.class.styles.map { |s| [s.name, s]}]
      end

      def template(format = :html)
        style(format).template(format)
      end


    end # InstanceMethods

  end
end

