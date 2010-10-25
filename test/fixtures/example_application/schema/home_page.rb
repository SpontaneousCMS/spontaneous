
class HomePage < Spontaneous::Page
	field :welcome_title
  field :introduction, :markdown
  
  slot :in_progress, :type => :Projects, :fields => { :title => "In Progress" }
  slot :completed, :type => :Projects, :fields => { :title => "Completed" }
  slot :archived, :type => :Projects, :fields => { :title => "Archived" }
  
  slot :pages do
  	allow :InfoPage
  end
  
  page_style :homepage
end
