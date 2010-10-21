
class HomePage < Spontaneous::Page
  field :introduction
  
  slot :in_progress, :class => :Projects, :fields => { :title => "In Progress" }
  slot :completed, :class => :Projects, :fields => { :title => "Completed" }
  slot :archived, :class => :Projects, :fields => { :title => "Archived" }
  
  slot :pages do
  	allow :InfoPage
  end
  
  page_style :homepage
end
