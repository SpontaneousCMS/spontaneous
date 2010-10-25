
class HomePage < Spontaneous::Page
	field :welcome_title
  field :introduction, :markdown
  
  slot :in_progress, :type => :ClientProjects, :fields => { :title => "In Progress" }
  slot :completed, :type => :ClientProjects, :fields => { :title => "Completed" }
  slot :archived, :type => :ClientProjects, :fields => { :title => "Archived" }
  
  slot :pages do
  	allow :InfoPage
  end
  
  page_style :homepage
end
