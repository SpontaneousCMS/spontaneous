# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Rack
  class PageController < Sinatra::Base
    attr_reader :content, :format

    def initialize(content, format)
      @content, @format = content, (format || :html).to_sym
      super(nil)
    end

    def page
      content.page
    end
  end
end
