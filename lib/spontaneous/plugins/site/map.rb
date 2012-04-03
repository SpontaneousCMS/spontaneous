# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Map
    extend ActiveSupport::Concern

    module ClassMethods
      def map(root_id=nil)
        page = \
          if root_id.nil?
            Spontaneous::Page.root
          else
            Spontaneous::Content.first :id => root_id
          end
        p page
        return nil unless page
        page.map_entry
      end
    end # ClassMethods
  end # Map
end
