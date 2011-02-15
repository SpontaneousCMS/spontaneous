# encoding: UTF-8


class ProjectImage < Spontaneous::Piece
  field :title

  field :image do
  	sizes :thumbnail => { :width => 100 }
  end

  # must be non-interpolated '' or %q{} or:
#   template <<-'HTML'
#   <li><a href="#{image.original.value}"><img src="#{image.thumbnail.src}" alt="#{title}" /></a></li>'
#   HTML

end
