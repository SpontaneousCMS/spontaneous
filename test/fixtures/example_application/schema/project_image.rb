# encoding: UTF-8


class ProjectImage < Piece
  field :title

  field :image do
  	size :thumbnail, :width => 100
  end

  # must be non-interpolated '' or %q{} or:
#   template <<-'HTML'
#   <li><a href="#{image.original.value}"><img src="#{image.thumbnail.src}" alt="#{title}" /></a></li>'
#   HTML

end
