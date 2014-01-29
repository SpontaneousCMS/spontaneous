# encoding: UTF-8

class Spontaneous::Site
  module Map
    extend Spontaneous::Concern

    def map(root_id=nil)
      page = \
      if root_id.nil?
        model::Page.root
      else
        model.get root_id
      end
      return nil unless page
      page.map_entry
    end
  end # Map
end
