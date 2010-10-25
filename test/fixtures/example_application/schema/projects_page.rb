
class ProjectsPage < Spontaneous::Page
  field :introduction, :markdown

  slot :projects do
    allow :Project
  end

  page_style :projects_page
end
