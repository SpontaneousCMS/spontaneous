# encoding: UTF-8

require 'simultaneous'

module Spontaneous::Output::Helpers
  module ScriptHelper

    extend self

    def script_helper
      @script_helper ||= Spontaneous::Asset::TagHelper.new(site, asset_manifests, '.js')
    end

    def scripts(*args)
      script_helper.urls(*args).map { |script|
        script_tag(script)
      }.join("\n")
    end

    alias_method :script, :scripts

    def script_tag(src)
      %(<script type="text/javascript" src="#{src}"></script>)
    end

    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end
