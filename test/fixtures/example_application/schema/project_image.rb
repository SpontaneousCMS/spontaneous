# encoding: UTF-8


class ProjectImage < Piece
  field :title

  field :image do
  	size :thumbnail do
      width 100
    end
  end

  # must be non-interpolated '' or %q{} or:
#   template <<-'HTML'
#   <li><a href="#{image.original.value}"><img src="#{image.thumbnail.src}" alt="#{title}" /></a></li>'
#   HTML

end
