# encoding: UTF-8

module Spontaneous
  class Layout
    attr_reader :name

    def initialize(name, options={})
      @name, @options = name.to_sym, options
    end

    def template(format = :html)
      ::File.join('layouts', "#{name}")
    end

    alias_method :path, :template

    def default?
      @options[:default]
    end

    def formats
      Spontaneous::Render.formats(self)
    end
  end
end

