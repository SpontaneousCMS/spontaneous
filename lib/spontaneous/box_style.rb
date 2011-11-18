# encoding: UTF-8


module Spontaneous
  class BoxStyle < Style
    attr_reader :box

    def self.excluded_classes
      [Spontaneous::Box].tap do |classes|
        classes.push(::Box) if defined?(::Box)
      end
    end

    def self.to_directory_name(klass)
      return nil if excluded_classes.include?(klass)
      super
    end

    def initialize(box, owner = nil)
      @box = box
      @owner = box._owner.class
    end

    def inline_template(format)
      nil
    end

    def try_supertype_styles
      []
    end




    def name
      box._name.to_s
    end

    def try_paths
      prototype = box._prototype
      box_name = box._name.to_s

      paths = owner_directory_paths(box_name)

      if style_name = prototype.default_style
        name = style_name.to_s
        paths.concat(owner_directory_paths(name))
        paths.concat(box_directory_paths(name))
      end

      if box.styles.empty?
        paths.concat(box_directory_names)
      else
        unless style_name = prototype.default_style
          box.styles.each do |style|
            name = style.name.to_s
            paths.concat(owner_directory_paths(name))
            paths.concat(box_directory_paths(name))
          end
        end
      end
      paths
    end

    def box_directory_names
      box_class = box._prototype.box_base_class
      box_supertypes = [box_class].concat(class_ancestors(box_class)).reject { |type| self.class.excluded_classes.include?(type) }
      return [nil] if box_supertypes.empty?
      box_supertypes.map { |type| self.class.to_directory_name(type) }
    end

    def box_directory_paths(name)
      box_directory_names.map { |d| [d, name] }
    end

    def anonymous_template
      Proc.new { '#{ render_content }' }
    end
  end
end

