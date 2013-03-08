# encoding: UTF-8

require 'sass'

module Spontaneous::Output::Helpers
  module StylesheetHelper
    extend self

    def stylesheets(*args)
      stylesheet_urls(*args).map { |stylesheet|
        stylesheet_tag(stylesheet)
      }.join("\n")
    end

    def stylesheet_urls(*args)
      options = args.extract_options!
      options.update(:development => development?)
      asset_environment.css(args.flatten, options)
    end

    alias_method :stylesheet, :stylesheets

    def stylesheet_tag(href)
      %(<link rel="stylesheet" href="#{href}" />)
    end

    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end
