# encoding: UTF-8

class Spontaneous::Site
  module Map
    extend Spontaneous::Concern

    module ClassMethods
      def map(root_id=nil)
        page = \
          if root_id.nil?
            content_model::Page.root
          else
            content_model.get root_id
          end
        return nil unless page
        page.map_entry
      end
    end # ClassMethods
  end # Map
end
