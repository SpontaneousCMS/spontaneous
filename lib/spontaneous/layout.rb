# encoding: UTF-8

module Spontaneous
  class Layout
    attr_reader :owner, :name

    def initialize(owner, name, options={})
      @owner, @name, @options = owner, name.to_sym, options
    end

    def schema_name
      "layout/#{owner.schema_id}/#{name}"
    end

    def schema_id
      Spontaneous::Schema.schema_id(self)
    end

    def schema_owner
      owner
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

