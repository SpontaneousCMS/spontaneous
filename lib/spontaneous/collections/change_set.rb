# encoding: UTF-8

module Spontaneous::Collections
  class ChangeSet
    attr_reader :changes

    def initialize(changes)
      @changes = changes.map do |change_or_id|
        change_or_id.is_a?(Spontaneous::Change) ? change_or_id : Spontaneous::Change[change_or_id]
      end
    end

    def pages
      @pages ||= page_ids.map { |id| Spontaneous::Content[id] }
    end

    def page_ids
      @page_ids ||= changes.inject([]) { |a, c| a += c.modified_list; a }.uniq.sort
    end

    def to_hash
      h = {
        :changes => changes.map { |c| c.to_hash },
      }
      # use compact because it's possible that some pages have been deleted since
      # the change was created and the best way to deal with them is to silently
      # ignore them and let the publishing mech delete them as usual
      h[:pages] = pages.compact.map  do |page|
        {
          :id => page.id,
          :title => page.title.to_s.escape_js,
          :path => page.path,
          :depth => page.depth
        }
      end
      h
    end
    def to_json
      to_hash.to_json
    end
  end
end

