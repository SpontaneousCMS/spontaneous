# encoding: UTF-8

module Spontaneous::Plugins
  module Layouts
    module ClassMethods
      def layout(name, options={})
        layouts << Spontaneous::Layout.new(self, name, options)
      end

      def layouts
        @layouts ||= []
      end

      def resolve_layout(layout_name, format = :html)
        if layout_name.blank?
          default_layout(format)
        else
          find_named_layout(layout_name, format)
        end
      end

      def find_named_layout(layout_name, format = :html)
        name = layout_name.to_sym
        unless layout = layouts.detect { |l| l.name == name }
          layout = supertype.resolve_layout(layout_name) if supertype_has_layout?
        end
        layout
      end

      def verify_layout_name(layout_name)
        # do I want this? instead of checking hierarchy, it should test for existance of template
        # raise Spontaneous::Errors::UnknownLayoutError.new(self, layout_name) unless find_named_layout(layout_name)
        layout_name
      end

      def default_layout(format = :html)
        if layouts.empty?
          if supertype_has_layout?
            supertype.default_layout(format)
          else
            Spontaneous::Layout.new(self, :standard)
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
      def layout(format = :html)
        resolve_layout(self.style_id, format)
      end

      def resolve_layout(style_id, format = :html)
        self.class.resolve_layout(style_id, format)
      end

      def layout=(layout_name)
        self.style_id = self.class.verify_layout_name(layout_name)
      end

      def template(format = :html)
        layout(format).template(format)
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        layout.formats.include?(format)
      end
    end # InstanceMethods
  end # Layouts
end # Spontaneous::Plugins

