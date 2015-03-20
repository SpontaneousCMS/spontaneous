# encoding: UTF-8


module Spontaneous::Collections
  class BoxSet < PrototypeSet

    attr_reader :owner

    def initialize(owner)
      super()
      @owner = owner
      initialize_from_prototypes
    end

    def reload
      values.each do |box|
        box.reload_box
      end
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
      map { |item| item.export }
    end

    def group(group_name)
      select { |box| box._prototype.group == group_name }
    end

    # A call to ${ content } within a layout template will call
    # this #render method. The obvious result of this should be
    # to just render each of the contained boxes.
    def render(format = :html, locals = {}, parent_context = nil)
      map { |box| box.render(format, locals, parent_context) }.join("\n")
    end

    def render_using(renderer, format = :html, locals = {}, parent_context = nil)
      map { |box| box.render_using(renderer, format, locals, parent_context) }.join("\n")
    end

    alias_method :render_inline, :render
    alias_method :render_inline_using, :render_using

    def destroy(origin)
      each { |box| box.destroy(origin) }
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

    def box_groups
      owner.class.box_prototypes.map { |prototype| prototype.group }.compact
    end


    def method_missing(method, *args)
      # allow access by group name e.g. instance.boxes.group_name
      if box_groups.include?(method)
        group(method)
        # self.select { |box| box._prototype.group == method }
      else
        super
      end
    end
  end
end
