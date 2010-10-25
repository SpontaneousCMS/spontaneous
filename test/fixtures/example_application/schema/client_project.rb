
class ClientProject < Spontaneous::Facet
  field :title
  field :url
  field :image
  field :description
  field :completed, :date

  slot :images do
    allow :ProjectImage
  end
end
