# encoding: UTF-8

module Spontaneous::Media::Store
  class Backend
    attr_reader :name
    attr_accessor :url_mapper

    def initialize(name)
      @name = name
      @url_mapper = default_url_mapper
    end

    def default_url_mapper
      Proc.new { |path| path }
    end

    def to_url(path)
      @url_mapper.call(path)
    end

    def accepts?(mimetype)
      return true if @accepts.nil?
      true
    end
  end
end
