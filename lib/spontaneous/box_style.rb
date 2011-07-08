# encoding: UTF-8


module Spontaneous
  class BoxStyle < Style
    attr_reader :box

    def self.to_directory_name(klass)
      return nil if klass == Spontaneous::Box
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
      if supertype && supertype != Spontaneous::Box
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
      paths = [ [owner_directory_name, box._name.to_s] ]

      if box.styles.empty?
        paths.push(box_directory_name)
      else
        if style_name = prototype.default_style
          name = style_name.to_s
          paths.push([owner_directory_name, name])
          paths.push([box_directory_name, name])
        else
          box.styles.each do |style|
            name = style.name.to_s
            paths.push([owner_directory_name, name])
            paths.push([box_directory_name, name])
          end
        end
      end

      paths
    end

    def anonymous_template
      Proc.new { "{{ render_content }}" }
    end
  end
end

