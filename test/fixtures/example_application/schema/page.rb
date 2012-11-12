require File.expand_path("../../lib/content", __FILE__)

class Page < Content::Page
  field :title, :string, :default => "New Page"
end
