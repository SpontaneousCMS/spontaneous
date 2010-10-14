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
    end

    module InstanceMethods
      def styles
        self.class.inline_styles
      end

      def style
        self.class.inline_styles[style_id]
      end
    end
  end
end

