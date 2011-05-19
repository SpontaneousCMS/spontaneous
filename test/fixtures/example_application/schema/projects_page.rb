# encoding: UTF-8


class ProjectsPage < Page
  field :introduction, :markdown

  box :projects do
    allow :Project
  end

  layout :projects
end
