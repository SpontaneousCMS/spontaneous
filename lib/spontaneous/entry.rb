
module Spontaneous
  class Entry
    alias_method :proxy_class, :class
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id|proxy_class/ }


    # def self.find_target(container, id)
    #   # Facet.get(id)
    #   container.page.facets.find { |f| f.id == id }
    # end

    def self.page(container, page, entry_style)
      create(PageEntry, container, page, entry_style)
    end

    def self.facet(container, facet, entry_style)
      create(Entry, container, facet, entry_style)
    end

    def self.create(entry_class, container, content, entry_style)
      content.save if content.new?
      entry = entry_class.new(container, content.id, nil)
      entry.target = content
      entry
    end

    attr_accessor :entry_store

    def initialize(container, target_id, style_name)
      @container = container
      @target_id = target_id
      @entry_style_name = style_name
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

    def load_target
      # target = proxy_class.find_target(@container, @target_id)
      Content[target_id].tap do |t|
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
        :id => target.id
      }
    end

    def inspect
      "#<#{self.proxy_class.name.demodulize}:#{self.object_id.to_s(16)} content=#{target_id} entry_style=\"#{@entry_style_name}\">"
    end
  end
end
