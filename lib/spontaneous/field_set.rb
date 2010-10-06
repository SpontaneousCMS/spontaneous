
module Spontaneous
  class FieldSet

    def initialize(owner, initial_values)
      @owner = owner
      @store = Hash.new
      initialize_from_prototypes(initial_values)
    end

    def initialize_from_prototypes(initial_values)
      values = (initial_values || []).inject({}) do |hash, value|
        hash[value[:name].to_sym] = value; hash
      end
      prototype_names = []
      owner.field_prototypes.each do |field_name, field_prototype|
        prototype_names << field_name # use this to look for orphaned fields in initial_values
        field = field_prototype.to_field(values[field_name] || {})
        add_field(field)
      end
    end


    def [](name)
      store[name.to_sym]
    end

    def owner
      @owner
    end

    def serialize
      store.map { |name, field| field.serialize }
    end

    protected

    def store
      @store
    end

    def add_field(field)
      field.owner = owner
      name = field.name
      store[name] = field
      meta.class_eval { define_method(name) { field } }
    end

    def meta
      @_meta ||= \
        class << self; self; end
    end

  end
end
