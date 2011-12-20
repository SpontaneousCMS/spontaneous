# encoding: UTF-8


module Spontaneous::Plugins
  module Aliases
    extend ActiveSupport::Concern

    included do
      many_to_one :target, :class => self, :reciprocal => :aliases
      one_to_many :aliases, :class => self, :key => :target_id, :reciprocal => :target
      add_association_dependencies :aliases => :destroy
    end
    # def self.configure(base)
    # end

    module ClassMethods
      def alias_of(*args)
        options_list, class_list = args.partition { |e| e.is_a?(Hash) }
        @alias_options = options_list.first || {}
        @alias_classes = class_list
        extend  ClassAliasMethods
        include AliasMethods
        include PieceAliasMethods unless page?
        include PageAliasMethods if page?
      end

      alias_method :aliases, :alias_of

      def targets
        targets = []
        classes = []
        @alias_classes.each do |source|
          case source
          when Proc
            targets.concat(source.call)
          else
            classes.concat(source.to_s.constantize.sti_subclasses_array)
          end
        end
        query = S::Content.filter(sti_key => classes.map { |c| c.to_s })
        if container_procs = @alias_options[:container]
          containers = [container_procs].flatten.map { |p| p.call }.flatten
          params = []
          containers.each do |container|
            if container.is_page?
              params << [:page_id, container.id]
            else
              params << [:box_sid, container.id]
            end
          end
          query = query.and(Sequel::SQL::BooleanExpression.from_value_pairs(params, :OR))
        end
        targets.concat(query.all)
        if filter = @alias_options[:filter] and filter.is_a?(Proc)
          targets.select(&filter)
        else
          targets
        end
      end

      def target_class(class_definition)

      end

      def alias?
        false
      end
    end # ClassMethods


    module ClassAliasMethods
      def alias?
        true
      end
    end

    # included only in instances that are aliases
    module AliasMethods
      def alias?
        true
      end

      def field?(field_name)
        super || target.class.field?(field_name)
      end

      def method_missing(method, *args)
        if target && target.respond_to?(method)
          if block_given?
            target.__send__(method, *args, &Proc.new)
          else
            target.__send__(method, *args)
          end
        else
          super
        end
      end


      def find_named_style(style_name)
        super or target.find_named_style(style_name)
      end

      def style
        if self.class.styles.empty?
          target.resolve_style(style_sid)
        else
          self.resolve_style(self.style_sid) or target.resolve_style(self.style_sid)
        end
      end

      def styles
        @styles ||= Spontaneous::Collections::PrototypeSet.new(target, :styles)
      end

      def export(user = nil)
        super.merge(:target => target.shallow_export(user), :alias_title => target.alias_title, :alias_icon => target.alias_icon_field.export)
      end

    end

    module PieceAliasMethods
      def path
        target.path
      end
    end

    module PageAliasMethods
      def slug
        target.slug
      end

      def layout
        # if this alias class has no layouts defined, then just use the one set on the target
        if self.class.layouts.empty?
          target.resolve_layout(self.style_sid)
        else
          # but if it does have layouts defined, use them
          self.resolve_layout(self.style_sid) or target.resolve_layout(self.style_sid)
        end
      end

      def find_named_layout(layout_name)
        super or target.find_named_layout(layout_name)
      end
    end

    # InstanceMethods

    def alias_title
      fields[:title].to_s
    end

    def alias_icon_field
      if field = fields.detect { |f| f.image? }
        field
      else
        nil
      end
    end
  end
end
