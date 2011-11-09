class Page < Spontaneous::Page
  field :title
  box :things, :type => :CustomBox do
    field :introduction
  end
end
