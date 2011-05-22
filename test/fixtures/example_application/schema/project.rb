# encoding: UTF-8


class Project < Page
  field :url
  field :image, :image do
    sizes :thumbnail => { :width => 100 }
  end
  field :description, :richtext

  box :text do
    allow :Text
    allow :InlineImage
  end

  layout :project
  style :inline
end
