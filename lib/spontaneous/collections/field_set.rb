# encoding: UTF-8

module Spontaneous::Collections
  class FieldSet < PrototypeSet

    attr_reader :owner

    def initialize(owner, initial_values, superobject = nil, superset_name = nil)
      super(superobject, superset_name)
      @owner = owner
      @field_data = initial_values
      initialize_from_prototypes
    end


    def serialize_db
      self.map { |field| field.serialize_db }
    end

    def export(user)
      owner.class.field_names.
        select { |name| owner.field_writable?(user, name) }.
        map { |name| self[name].export(user) }
    end

    def saved
      self.each { |field| field.mark_unmodified }
    end

    def with_dynamic_default_values
      select { |field| field.prototype.dynamic_default? }
    end

    def prototypes
      map(&:prototype)
    end

    # Lazily load fields by name
    def named(name)
      super || load_field(owner.field_prototypes[name.to_sym])
    end

    # A call to ${ fields } within a template will call
    # this #render method.
    # This should only be used during development
    #
    def render(format = :html, locals = {}, parent_context = nil)
      map { |field| wrap_field_value(field, field.render(format, locals), format) }.join("\n")
    end

    alias_method :render_inline, :render

    def render_using(renderer, format = :html, locals = {}, parent_context = nil)
      map { |field| wrap_field_value(field, field.render_using(renderer, format, locals), format) }.join("\n")
    end

    alias_method :render_inline_using, :render_using

    protected

    def wrap_field_value(field, value, format)
      case format
      when "html", :html
        classes = [owner.class.to_s.dasherize.downcase, "field", field.name].join(" ")
        id = "field-#{field.id.gsub(/\//, "-")}"
        [ %(<div class="#{classes}" id="#{id}">), value, "</div>" ].join
      else
        value
      end
    end

    def initialize_from_prototypes
      owner.field_prototypes.each do |field_prototype|
        add_field(field_prototype)
      end
    end

    def field_values
      @field_values ||= parse_field_data(@field_data)
    end

    def parse_field_data(initial_values)
      values = (initial_values || []).map do |value|
        value = S::Field.deserialize_field(value)
        [Spontaneous.schema.uids[value[:id]], value]
      end
      Hash[values]
    end

    # overwritten because otherwise the iterators in PrototypeSet don't
    # know which keys we are supposed to have
    def local_order
      owner.field_prototypes.keys
    end

    def add_field(field_prototype)
      name = field_prototype.name
      getter_name = name
      setter_name = "#{name}="
      singleton_class.class_eval do
        define_method(getter_name) { |*args| named(name).tap { |f| f.template_params = args } }
        define_method(setter_name) { |value| named(name).value = value }
      end
    end

    def load_field(field_prototype)
      return nil if field_prototype.nil?
      field_prototype.to_field(owner, field_values[field_prototype.schema_id]).tap do |field|
        field.owner = owner
        self[field_prototype.name] = field
      end
    end
  end
end
