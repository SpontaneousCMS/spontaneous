# encoding: UTF-8


module Spontaneous::Plugins
  module SiteMap
    module ClassMethods
    end

    module InstanceMethods
      def map_children
        self.children.map { |c| c.map_entry }
      end

      def map_entry
        shallow_map_entry.merge({
          :children => self.children.map {|c| c.shallow_map_entry },
          :generation => self.generation.map {|c| c.shallow_map_entry },
          :ancestors => self.ancestors.map {|c| c.shallow_map_entry },
        })
      end
      def shallow_map_entry
        {
          :id => id,
          :title => fields.title.value,
          :path => path,
          :type => self.class.ui_class,
          :type_id => self.class.schema_id,
          :children => self.children.length,
          :depth => depth
        }
      end
    end
  end
end
