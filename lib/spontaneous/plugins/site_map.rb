# encoding: UTF-8

module Spontaneous::Plugins
  module SiteMap
    extend Spontaneous::Concern

    # InstanceMethods
    def map_children
      self.children.map { |c| c.map_entry }
    end

    def map_entry
      shallow_map_entry.merge({
        :children => grouped_page_list(self.children),
        :generation => grouped_page_list(self.generation),
        :ancestors => self.ancestors.map {|c| c.shallow_map_entry }
      })
    end

    def grouped_page_list(pages)
      Hash.new { |hash, key| hash[key] = [] }.tap { |map|
        pages.each do |p|
          return {:Root => [p.shallow_map_entry]} if p.container.nil? # guard for site root
          map[p.container._prototype.title] << p.shallow_map_entry
        end
      }
    end

    def shallow_map_entry
      {
        :id => id,
        :title => fields.title.value,
        :path => path,
        :slug => slug,
        :type => self.class.ui_class,
        :type_id => self.class.schema_id,
        :children => self.children.length,
        :depth => depth
      }
    end
  end
end
