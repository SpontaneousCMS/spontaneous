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

      def all_layouts
        layouts.concat(supertype_has_layout? ? supertype.all_layouts : [])
      end

      def layout_prototypes
        Hash[ all_layouts.map { |s| [s.name, s] } ]
      end

      def resolve_layout(layout_sid, format = :html)
        if layout_sid.nil? #layout_name.blank?
          default_layout(format)
        else
          find_layout(layout_sid, format)
        end
      end

      def find_layout(layout_sid, format = :html)
        # name = layout_name.to_sym
        unless layout = layouts.detect { |l| l.schema_id == layout_sid }
          layout = supertype.resolve_layout(layout_sid) if supertype_has_layout?
        end
        layout
      end

      def find_named_layout(layout_name)
        layout_prototypes[layout_name.to_sym]
      end

      def verify_layout_name(layout_name)
        # do I want this? instead of checking hierarchy, it should test for existance of template
        # raise Spontaneous::Errors::UnknownLayoutError.new(self, layout_name) unless find_named_layout(layout_name)
        if layout = layout_prototypes[layout_name.to_sym]
          layout.schema_id
        else
          nil
        end
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
        resolve_layout(self.style_sid, format)
      end

      def resolve_layout(style_sid, format = :html)
        self.class.resolve_layout(style_sid, format)
      end

      # def layout=(layout_name)
      #   self.style_sid = self.class.verify_layout_name(layout_name)
      # end
      def layout=(layout)
        self.style_sid = layout_to_schema_id(layout)
      end

      def layout_to_schema_id(layout)
        sid = nil
        if layout.respond_to?(:schema_id)
          sid = layout.schema_id
        else
          if Spontaneous::Schema::UID === layout
            sid = layout
          else
            if s = self.find_named_layout(layout)
              sid = s.schema_id
            end
          end
        end
        sid
      end

      def find_named_layout(layout_name)
        self.class.find_named_layout(layout_name)
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

