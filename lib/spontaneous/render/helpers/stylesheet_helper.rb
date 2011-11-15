# encoding: UTF-8

module Spontaneous::Render::Helpers
  module StylesheetHelper
    def stylesheet(*args)
      stylesheets = args
      stylesheets.map do |stylesheet|
        %(<link rel="stylesheet" href="#{stylesheet}.css" />)
      end.join("\n")
    end

    alias_method :stylesheets, :stylesheet
  end
end
