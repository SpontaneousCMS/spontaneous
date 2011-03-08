# encoding: UTF-8


class Project < Spontaneous::Page
  field :url
  field :image, :image do
    sizes :thumbnail => { :width => 100 }
  end
  field :description, :richtext

  box :text do
    allow :Text
    allow :InlineImage
  end

  page_style :page
  inline_style :inline
end
