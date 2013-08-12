# encoding: UTF-8

module Spontaneous::Field
  class Tags < Base

    include Enumerable

    def outputs
      [:html, :tags]
    end

    def generate_html(value)
      value
    end

    TAG_PARSER_RE = /"([^"]+)"|([^ ]+)/

    def generate_tags(value)
      return [] if value.blank?
      (value).scan(TAG_PARSER_RE).flatten.compact
    end

    def taglist
      values[:tags] || []
    end

    def each(&block)
      taglist.each(&block)
    end

    self.register
  end
end
