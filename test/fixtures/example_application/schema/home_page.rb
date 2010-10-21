
class HomePage < Spontaneous::Page
	field :welcome_title
  field :introduction, :markdown
  
  slot :in_progress, :class => :Projects, :fields => { :title => "In Progress" }
  slot :completed, :class => :Projects, :fields => { :title => "Completed" }
  slot :archived, :class => :Projects, :fields => { :title => "Archived" }
  
  slot :pages do
  	allow :InfoPage
  end
  
  page_style :homepage
end
