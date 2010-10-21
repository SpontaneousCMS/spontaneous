
class Project < Spontaneous::Facet
  field :title
  field :url
  field :image
  field :description
  #field :completed
  
  slot :images do
    allow :ProjectImage
  end
  
end
