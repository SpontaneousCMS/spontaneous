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

    def initialize(box)
      @box = box
      @owner = box._owner.class
    end

    def inline_template(format)
      nil
    end

    def supertype_template(format)
      supertype = box.class.supertype
      if supertype && supertype != Spontaneous::Box && supertype != ::Box
        self.class.new(supertype).template(format)
      else
        nil
      end
    end

    def name
      box._name.to_s
    end

    def try_paths
      prototype = box._prototype
      box_directory_name = self.class.to_directory_name(prototype.box_base_class)
      box_name = box._name.to_s

      paths = owner_directory_paths(box_name)


      if style_name = prototype.default_style
        name = style_name.to_s
        paths.concat(owner_directory_paths(name))
        paths.push([box_directory_name, name])
      end

      if box.styles.empty?
        paths.push(box_directory_name)
      else
        unless style_name = prototype.default_style
          box.styles.each do |style|
            name = style.name.to_s
            paths.concat(owner_directory_paths(name))
            # paths.push([owner_directory_name, name])
            paths.push([box_directory_name, name])
          end
        end
      end

      paths
    end

    def anonymous_template
      Proc.new { '#{ render_content }' }
    end
  end
end

