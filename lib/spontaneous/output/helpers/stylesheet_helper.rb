# encoding: UTF-8

require 'sass'

module Spontaneous::Output::Helpers
  module StylesheetHelper
    extend self

    def stylesheet_helper
      @stylesheet_helper ||= Spontaneous::Asset::TagHelper.new(site, asset_manifests, '.css')
    end

    def stylesheets(*args)
      stylesheet_helper.urls(*args).map { |stylesheet|
        stylesheet_tag(stylesheet)
      }.join("\n")
    end

    alias_method :stylesheet, :stylesheets

    def stylesheet_tag(href)
      %(<link rel="stylesheet" href="#{href}" />)
    end

    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end
