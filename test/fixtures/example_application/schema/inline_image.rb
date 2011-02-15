# encoding: UTF-8


class InlineImage < Spontaneous::Piece
  field :title
  field :image, :image do
    sizes :inline => { :width => 300 }
  end
end
