
class Project < Spontaneous::Page
  field :url
  field :image
  field :description

  slot :text do
    allow :Text
    allow :InlineImage
  end

  page_style :page
  inline_style :inline
end
