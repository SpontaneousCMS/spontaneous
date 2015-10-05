# encoding: UTF-8

module Spontaneous::Prototypes
  class LayoutPrototype < StylePrototype
    def schema_name
      Spontaneous::Schema.schema_name('layout', owner.schema_id, name)
    end

    def layout(owner)
      Spontaneous::Layout.new(owner, self)
    end

    def formats
      Spontaneous::Render.formats(self)
    end
  end # LayoutPrototype
end # Spontaneous::Prototypes
