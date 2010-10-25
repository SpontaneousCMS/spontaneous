
class ClientProject < Spontaneous::Facet
  field :title
  field :url
  field :image
  field :description, :markdown
  field :completed, :date

  slot :images do
    allow :ProjectImage
  end
end
