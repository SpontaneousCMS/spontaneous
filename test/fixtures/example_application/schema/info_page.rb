# encoding: UTF-8


class InfoPage < Page
  box :contents do
    allow :Text
    allow :InlineImage
  end

  layout :info

  inline_style :inline
end