# encoding: UTF-8

module Spontaneous::Plugins
  module Layouts
    module ClassMethods
      def layout(name, options={})
        layout_prototypes[name] = Spontaneous::Prototypes::LayoutPrototype.new(self, name, options)
      end

      def layout_prototypes
        @layout_prototypes ||= Spontaneous::Collections::PrototypeSet.new(supertype, :layout_prototypes)
      end

      alias_method :layouts, :layout_prototypes

      def resolve_layout(layout_sid)
        if layout_sid.nil? #layout_name.blank?
          default_layout
        else
          find_layout(layout_sid)
        end
      end

      def default_layout
        if prototype = (layouts.detect { |prototype| prototype.default? } || layouts.first)
          prototype.layout(self)
        else
          Spontaneous::Layout::Default.new(self)
        end
      end

      def find_layout(layout_sid)
        if prototype = layout_prototypes.sid(layout_sid)
          prototype.layout(self)
        end
      end

      def find_named_layout(layout_name)
        layout_prototypes[layout_name.to_sym]
      end
    end # ClassMethods

    module InstanceMethods
      def layout
        resolve_layout(self.style_sid)
      end

      def resolve_layout(style_sid)
        self.class.resolve_layout(style_sid)
      end

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
        layout.template(format)
      end

      def provides_format?(format)
        format = (format || :html).to_sym
        layout.formats.include?(format)
      end
    end # InstanceMethods
  end # Layouts
end # Spontaneous::Plugins

