# encoding: UTF-8


class InlineImage < Piece
  field :title
  field :image, :image do
    size :inline do
      width 300
    end
  end
end
