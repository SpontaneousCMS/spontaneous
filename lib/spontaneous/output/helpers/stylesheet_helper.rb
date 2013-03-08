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
      asset_environment.css(args.flatten)
    end

    alias_method :stylesheet, :stylesheets

    def stylesheet_tag(href)
      href = "#{href}.css" unless href =~ /\.css$/o
      %(<link rel="stylesheet" href="#{href}" />)
    end

    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end
