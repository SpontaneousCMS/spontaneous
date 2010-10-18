
class HomePage < Spontaneous::Page
  slot :introduction
  slot :in_progress, :class => :Projects
  slot :completed, :class => :Projects
  slot :archived, :class => :Projects
end
