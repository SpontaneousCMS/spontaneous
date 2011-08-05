# encoding: UTF-8


module Spontaneous::Collections
  class BoxSet < PrototypeSet

    attr_reader :owner

    def initialize(owner)
      super()
      @owner = owner
      initialize_from_prototypes
    end

    def initialize_from_prototypes
      owner.class.boxes.each do |box_prototype|
        box = box_prototype.get_instance(owner)
        add_box(box)
      end
    end

    alias_method :get_without_ranges, :[]

    def [](*args)
      if args.length == 1
        get_single(args[0])
      else
        args.map { |index| get_single(index) }.flatten
      end
    end

    def export
      self.map { |item| item.export }
    end

    protected

    def get_single(index)
      case index
      when Range
        order[index].map { | name | named(name) }
      else
        get_without_ranges(index)
      end
    end

    def add_box(box)
      self[box._prototype.name] = box
      getter_name = box._prototype.name
      singleton_class.class_eval do
        define_method(getter_name) { |*args| box.tap { |b| b.template_params = args } }
      end
    end
  end
end

