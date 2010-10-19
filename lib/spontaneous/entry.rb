
module Spontaneous
  class Entry < ProxyObject

    def self.find_target(container, id)
      if container.page
        container.page.facets.find { |f| f.id == id }
      else
        Content[id]
      end
    end

    def self.page(container, page, entry_style)
      create(PageEntry, container, page, entry_style)
    end

    def self.facet(container, facet, entry_style)
      create(Entry, container, facet, entry_style)
    end

    def self.create(entry_class, container, content, entry_style)
      content.save if content.new?
      entry = entry_class.new(container, content.id, entry_style ? entry_style.name : nil)
      entry.target = content
      entry
    end

    attr_accessor :entry_store

    def initialize(container, target_id, style_name)
      @container = container
      @target_id = target_id
      @entry_style_name = style_name.to_sym if style_name
    end

    def target_id
      @target_id
    end

    def container
      @container
    end

    def target
      @target ||= load_target
    end

    def label
      @label ||= read_label
    end

    def read_label
      l = target.label
      return nil if l.nil? or l.empty?
      target.label.to_sym
    end

    def style
      if @entry_style_name
        target.styles[@entry_style_name]
      else
        target.anonymous_style
      end
    end

    def template(format=:html)
      style.template(format)
    end

    def style=(style)
      style = target.styles[style] unless style.is_a?(Style)
      @entry_style_name = style.name
      target[:style_id] = style.name
      # because it's not obvious that a change to an entry
      # will affect the fields of the target facet
      # make sure that the target is saved using an instance hook
      @container.after_save_hook do
        target.save
      end
      @container.entry_modified!(self)
    end

    def style_name
      @entry_style_name
    end

    def load_target
      # Content[target_id].tap do |t|
      proxy_class.find_target(@container, @target_id).tap do |t|
        t.entry = self
      end
    end

    def target=(target)
      @target = target
    end

    def method_missing(method, *args, &block)
      self.target.send(method, *args, &block)
    end

    def serialize
      {
        :class => self.proxy_class.name.demodulize,
        :id => target.id,
        :style => @entry_style_name,
        :slot => target.slot_id
      }
    end

    def inspect
      "#<#{self.proxy_class.name.demodulize}:#{self.object_id.to_s(16)} content=#{target} entry_style=\"#{@entry_style_name}\" label=\"#{label}\" slot_id=\"#{slot_id}\">"
    end

    def to_hash
      target.to_hash.merge(styles_to_hash)
    end

    def styles_to_hash
      {
        :style => @entry_style_name.to_s,
        :styles => container.available_styles(target).map { |s| s.name.to_s },
      }
    end
  end
end
