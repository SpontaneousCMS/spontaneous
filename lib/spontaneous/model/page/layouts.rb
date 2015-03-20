# encoding: UTF-8

module Spontaneous::Model::Page
  module Layouts
    extend Spontaneous::Concern

    module ClassMethods
      def layout(name = nil, options = {}, &block)
        if block_given?
          layout_procs[name] = block
        else
          raise "Layouts must be given a name" if name.blank?
          layout_prototypes[name] = Spontaneous::Prototypes::LayoutPrototype.new(self, name, options)
        end
      end

      def layout_procs
        @layout_procs ||= {}
      end

      def layout_prototypes
        @layout_prototypes ||= Spontaneous::Collections::PrototypeSet.new(supertype, :layout_prototypes)
      end

      alias_method :layouts, :layout_prototypes

      def resolve_layout(layout_sid)
        if layout_sid.blank?
          default_layout
        else
          find_layout(layout_sid)
        end
      end

      def default_layout
        return Spontaneous::Layout::Anonymous.new(layout_procs) unless layout_procs.empty?
        if prototype = (layouts.hierarchy_detect { |prototype| prototype.default? } || layouts.local_first)
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

    # InstanceMethods

    def layout
      resolve_layout(layout_sid)
    end

    def resolve_layout(layout_sid)
      self.class.resolve_layout(layout_sid)
    end

    def layout=(layout)
      self.layout_sid = layout_to_schema_id(layout)
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

    def template(format = :html, renderer = Spontaneous::Output::default_renderer)
      layout.template(format, renderer)
    end
  end # Layouts
end # Spontaneous::Plugins
