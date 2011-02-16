# encoding: UTF-8


class InfoPage < Spontaneous::Page
  box :text do
    allow :Text
    allow :InlineImage
  end

  page_style :page
  inline_style :inline
end