# encoding: UTF-8

module Spontaneous::Plugins
  module PageStyles

    module ClassMethods
      def page_style(name, options={})
        page_styles << Spontaneous::Style.new(self, name, options)
      end

      def page_styles
        @page_styles ||= Spontaneous::StyleDefinitions.new
      end
    end

    module InstanceMethods
      def page_styles
        self.class.page_styles
      end

      def style
        style = page_styles[self.style_id] || default_page_style
        style
      end

      def default_page_style
        page_styles.first
      end

      def style=(page_style)
        case page_style
        when String, Symbol
          if page_styles[page_style]
            self.style_id = page_style
          end
        when Style
          self.style_id = page_style.name
        end
      end
    end
  end
end

