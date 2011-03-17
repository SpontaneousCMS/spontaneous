# encoding: UTF-8


class HomePage < Page
	field :welcome_title
  field :introduction, :markdown

  box :in_progress, :type => :ClientProjects, :fields => { :title => "In Progress" }
  box :completed, :type => :ClientProjects, :fields => { :title => "Completed" }
  box :archived, :type => :ClientProjects, :fields => { :title => "Archived" }

  box :pages do
  	allow :InfoPage
  end

  page_style :page

  def prototype
    # make sure things are working with a prototype method
  end
end

