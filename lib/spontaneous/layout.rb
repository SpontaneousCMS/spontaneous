# encoding: UTF-8

module Spontaneous
  class Layout
    attr_reader :name

    def initialize(name, options={})
      @name, @options = name.to_sym, options
    end

    def template
      ::File.join('layouts', "#{name}")
    end

    def default?
      @options[:default]
    end
  end
end

