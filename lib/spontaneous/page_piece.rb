# encoding: UTF-8


module Spontaneous
  class PagePiece < ProxyObject
    extend Plugins
    plugin Plugins::Render

    attr_accessor :container
    attr_reader :target, :style_id

    def initialize(container, target, style_id)
      @container, @target, @style_id = container, target, style_id
    end

    def id
      target.id
    end

    def depth
      container.content_depth + 1
    end

    def style(format = :html)
      target.class.resolve_style(style_name, format)
    end

    def entry
      self
    end

    def to_hash
      target.to_shallow_hash.merge(styles_to_hash).merge({
        :depth => self.depth
      })
    end

    def styles_to_hash
      {
        :style => style_id.to_s,
        :styles => container.available_styles(target).map { |s| s.schema_id.to_s },
      }
    end

    def serialize_entry
      {
        :page => target.id,
        :style_id => @style_id
      }
    end

    def style=(style)
      @style_id = style_to_schema_id(style)
      # because it's not obvious that a change to an entry
      # will affect the fields of the container piece
      # make sure that the container is saved using an instance hook
      target.after_save_hook do
        container.save
      end
      container.entry_modified!(self)
    end

    def style
      target.resolve_style(style_id)
    end

    def template(format = :html)
      style.template(format)
    end

    def method_missing(method, *args)
      if block_given?
        self.target.__send__(method, *args, &Proc.new)
      else
        self.target.__send__(method, *args)
      end
    end
  end
end

