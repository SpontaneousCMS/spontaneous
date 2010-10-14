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
      def style
        self.class.page_styles[self.style_id]
      end

      def style=(page_style)
        self.style_id = page_style.name
      end
    end
  end
end

