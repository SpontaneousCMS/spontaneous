# encoding: UTF-8


module Spontaneous::Plugins
  module Aliases

    def self.configure(base)
      base.many_to_one :target, :class => base, :reciprocal => :aliases
      base.one_to_many :aliases, :class => base, :key => :target_id, :reciprocal => :target
      base.add_association_dependencies :aliases => :destroy
    end

    module ClassMethods
      def alias_of(*class_list)
        @alias_classes = class_list
        include AliasMethods
        include PageAliasMethods if page?
      end

      def targets
        targets = []
        target_classes.each do |target_class|
          targets += target_class.sti_subclasses_array
        end
        S::Content.filter(sti_key => targets.map { |t| t.to_s }).all
      end

      def target_classes
        @target_classes ||= @alias_classes.map { |c| c.to_s.constantize }
      end
    end

    # included only in classes that are aliases
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

      def styles
        @styles ||= S::StyleDefinitions.new(self.class.inline_styles, [target, :styles])
      end
    end

    module PageAliasMethods
      def path
        @_path ||= [parent.path, target.slug].join(S::SLASH)
      end

      def calculate_path
        ""
      end

      def layout
        # if this alias class has no layouts defined, then just use the one set on the target
        if self.class.layouts.empty?
          target.resolve_layout(self.style_id)
        else
          # but if it does have layouts defined, use them
          self.resolve_layout(self.style_id) or target.resolve_layout(self.style_id)
        end
      end

      # def layouts
      #   @layouts ||= S::StyleDefinitions.new(self.class.layouts, [target, :layouts])
      # end
    end
  end
end


