
class HomePage < Spontaneous::Page
  field :introduction
  
  slot :in_progress, :class => :Projects
  slot :completed, :class => :Projects
  slot :archived, :class => :Projects
  
  slot :pages do
  	allow :InfoPage
  end
  
  page_style :homepage
end
