# encoding: UTF-8

module Spontaneous::Plugins
  module Layouts
    module ClassMethods
      def layout(name, options={})
        layouts << Spontaneous::Layout.new(name, options)
      end

      def layouts
        @layouts ||= []
      end

      def resolve_layout(layout_name)
        if layout_name.blank?
          default_layout
        else
          find_named_layout(layout_name)
        end
      end

      def find_named_layout(layout_name)
        name = layout_name.to_sym
        unless layout = layouts.detect { |l| l.name == name }
          layout = supertype.resolve_layout(layout_name) if supertype_has_layout?
        end
        layout
      end

      def verify_layout_name(layout_name)
        raise Spontaneous::Errors::UnknownLayoutError.new(self, layout_name) unless find_named_layout(layout_name)
        layout_name
      end

      def default_layout
        if layouts.empty?
          if supertype_has_layout?
            supertype.default_layout
          else
            Spontaneous::Layout.new(:standard)
          end
        else
          layouts.detect { |l| l.default? } or layouts.first
        end
      end

      def supertype_has_layout?
        supertype? and supertype.respond_to?(:default_layout)
      end
    end # ClassMethods

    module InstanceMethods
      def layout
        self.class.resolve_layout(self.style_id)
      end

      def layout=(layout_name)
        self.style_id = self.class.verify_layout_name(layout_name)
      end

      def template
        layout.template
      end
    end # InstanceMethods
  end # Layouts
end # Spontaneous::Plugins

