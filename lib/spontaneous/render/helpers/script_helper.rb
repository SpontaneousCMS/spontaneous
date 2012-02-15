# encoding: UTF-8

module Spontaneous::Render::Helpers
  module ScriptHelper
    extend self

    def script(*args)
      scripts = args.flatten
      scripts.map do |script|
        %(<script type="text/javascript" src="#{script}.js"></script>)
      end.join("\n")
    end

    alias_method :scripts, :script
  end
end

