# encoding: UTF-8


class ClientProject < Spontaneous::Piece
  field :title
  field :url
  field :image
  field :second_image, :image
  field :description, :markdown
  field :completed, :date

  slot :images do
    allow :ProjectImage
  end
  slot :other_stuff do
    allow :ProjectImage
  end
end
