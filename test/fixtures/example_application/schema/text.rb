
class Text < Spontaneous::Facet
  field :text
  #inline_style :text
  template '<p>#{text}</p>'
end
