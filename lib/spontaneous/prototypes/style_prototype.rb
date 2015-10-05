# encoding: UTF-8

module Spontaneous::Prototypes
  class StylePrototype
    attr_reader :owner, :name, :options

    def initialize(owner, name, options = {})
      @owner, @name, @options = owner, name, options
    end

    def default?
      options[:default]
    end

    def schema_name
      Spontaneous::Schema.schema_name('style', owner.schema_id, name)
    end

    def schema_owner
      owner
    end

    def owner_sid
      schema_owner.schema_id
    end

    def style(owner)
      Spontaneous::Style.new(owner, self)
    end

    def schema_id
      Spontaneous.schema.to_id(self)
    end

    def export(user)
      {
        :name => name.to_s,
        :schema_id => schema_id.to_s
      }
    end
  end # StylePrototype
end # Spontaneous::Prototypes
