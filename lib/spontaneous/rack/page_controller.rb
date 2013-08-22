# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Rack
  class PageController < Sinatra::Base
    include Spontaneous::Rack::Public
    attr_reader :content, :page, :output

    def initialize(content, output)
      @content, @output = content, (output || :html).to_sym
      @page = content.page
      super(nil)
    end

    def render(*args)
      params = args.extract_options!
      output = @output
      page   = @page
      args.each do |arg|
        case arg
        when Symbol
          output = arg
        when Spontaneous::Content
          page = arg
        end
      end
      _render_page_with_output(page, output, params)
    end
  end
end
