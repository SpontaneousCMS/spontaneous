# encoding: UTF-8

module Spontaneous
  class ChangeSet
    attr_reader :changes

    def initialize(changes)
      @changes = changes.map do |change_or_id|
        change_or_id.is_a?(Change) ? change_or_id : Change[change_or_id]
      end
    end

    def pages
      @pages ||= page_ids.map { |id| Content[id] }
    end

    def page_ids
      @page_ids ||= changes.inject([]) { |a, c| a += c.modified_list; a }.uniq.sort
    end

    def to_hash
      h = {
        :changes => changes.map { |c| c.to_hash },
      }
      h[:pages] = pages.map  do |page|
        {
          :id => page.id,
          :title => page.title.to_s.escape_js,
          :path => page.path
        }
      end
      h
    end
    def to_json
      to_hash.to_json
    end
  end
end

