# encoding: UTF-8


module Spontaneous::Model::Core
  module Aliases
    extend Spontaneous::Concern

    module ClassMethods
      def alias_of(*args)
        options_list, class_list = args.partition { |e| e.is_a?(Hash) }
        @alias_options = options_list.first || {}
        @alias_classes = class_list
        extend  ClassAliasMethods
        include AliasMethods
        include PieceAliasMethods unless page?
        include PageAliasMethods  if page?
        # alias_method :target,  :__target
        alias_method :target=, :__target=
      end


      alias_method :aliases, :alias_of

      def targets(owner = nil, box = nil, options = {})
        targets = []
        classes = []
        proc_args = [owner, box].compact
        @alias_classes.each do |source|
          case source
          when Proc
            targets.concat(Array(source[*proc_args]))
          else
            type = source.to_s.constantize
            classes.push(type)
            classes.concat(type.subclasses)
          end
        end

        query = content_model.filter(type_sid: classes.map { |c| c.schema_id })

        if (container_procs = @alias_options[:container])
          containers = [container_procs].flatten.map { |p| p[*proc_args] }.flatten
          params = []
          containers.each do |container|
            if container.is_page?
              params << Sequel::SQL::BooleanExpression.new(:'=', :page_id, container.id)
            else
              box_params = [
                [:box_sid, container.schema_id],
                [:owner_id, container.owner.id]
              ]
              params << Sequel::SQL::BooleanExpression.from_value_pairs(box_params, :AND)
            end
          end
          container_query = params[1..-1].inject(params.first) { |q, expr| q = q | expr; q }
          query = query.and(container_query)
        end
        targets.concat(query.all)

        if (filter = @alias_options[:filter]) and filter.is_a?(Proc)
          filtered = []
          targets.each { |target|
            filtered << target if filter[*([target, owner, box][0...(filter.arity)])]
          }
          targets = filtered
        end

        if @alias_options[:unique] && box
          existing = box.map { |entry| entry.target || entry }
          targets.reject! { |target| existing.include?(target) }
        end

        if (query =  options[:search])
          targets.select! { |target| query === target.alias_title }
        end
        targets
      end

      def target_class(class_definition)
      end

      def alias?
        false
      end
    end # ClassMethods


    module ClassAliasMethods
      def for_target(target_id)
        new(target_id: target_id)
      end

      def alias?
        true
      end

      def use_configured_generator(generator_name, *args)
        return nil unless @alias_options.key?(generator_name)
        (_generator = @alias_options[generator_name]).call(*args)
      end

      def lookup_target(target_id)
        use_configured_generator(:lookup, target_id)
      end

      def target_slug(target)
        use_configured_generator(:slug, target)
      end
    end

    # included only in instances that are aliases
    module AliasMethods
      # If we're being created as an alias to a hidden target then we should be
      # born hidden and have our visibility linked to our target.
      def before_create
        set_visible(false, target.hidden_origin || target.id) if target && target.hidden?
        super
      end

      def alias?
        true
      end

      def target
        (_target = self.class.lookup_target(self.target_id)) and return _target
        __target
      end

      def fields
        @field_set ||= Spontaneous::Collections::FieldSet.new(self, field_store, target, :fields)
      end

      def field?(field_name)
        super || (target && target.class.field?(field_name))
      end

      def respond_to_missing?(name, include_private = false)
        (target && target.respond_to?(name, include_private)) || super
      end

      def respond_to?(name, include_private = false)
        super || respond_to_missing?(name, include_private)
      end

      def method_missing(method, *args)
        if target && respond_to_missing?(method)
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
        super or (target && target.find_named_style(style_name))
      end

      # Aliases are unique in that their style depends on the instance as well
      # as the class.
      def style
        Spontaneous::Style::AliasStyle.new(self)
      end

      def styles
        @styles ||= Spontaneous::Collections::PrototypeSet.new(target, :styles)
      end

      def shallow_export(user = nil)
        super.merge(target: exported_target(user), alias_title: target.alias_title, alias_icon: target.exported_alias_icon)
      end

      def exported_target(user = nil)
        case target
        when content_model
          target.shallow_export(user)
        else
          target.to_json
        end
      end

      def hidden?
        super || target.nil?
      end
    end

    module PieceAliasMethods
      def path
        target.path
      end
    end

    module PageAliasMethods
      def slug
        return super if target.nil?
        unless target.respond_to?(:slug)
          slug = self.class.target_slug(target) and return slug
        end
        target.slug
      end

      def layout
        # if this alias class has no layouts defined, then just use the one set on the target
        if self.class.layouts.empty? && !target.nil?
          target.resolve_layout(layout_sid)
        else
          # but if it does have layouts defined, use them
          resolve_layout(layout_sid) or target.try(:resolve_layout, layout_sid)
        end
      end

      def find_named_layout(layout_name)
        super or target.try(:find_named_layout, layout_name)
      end
    end

    # InstanceMethods

    # Used as the title for this instance in the list of potential targets for
    # and alias.
    def alias_title
      alias_title_field.to_s
    end

    def alias_title_field
      unless (field = fields[:title])
        field = fields.detect { |f| f.is_a?(Spontaneous::Field::String) }
      end
      field
    end

    def alias_icon_field
      if (field = fields.detect { |f| f.image? })
        field
      else
        nil
      end
    end

    def exported_alias_icon
      return nil unless alias_icon_field
      alias_icon_field.export
    end
  end
end
