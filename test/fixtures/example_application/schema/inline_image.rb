
class InlineImage < Spontaneous::Facet
  field :title
  field :image, :image do
    sizes :inline => { :width => 300 }
  end
end
