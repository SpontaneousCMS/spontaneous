# encoding: UTF-8


class Project < Page
  field :url
  field :image, :image do
    size :thumbnail do
      width 100
    end
  end

  field :description, :richtext

  box :text do
    allow :Text
    allow :InlineImage
  end

  layout :project
  style :inline
end
