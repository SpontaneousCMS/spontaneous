# encoding: UTF-8

require 'coffee-script'
require 'simultaneous'

module Spontaneous::Output::Helpers
  module ScriptHelper
    extend self

    def scripts(*args)
      script_urls(*args).map { |script|
        script_tag(script)
      }.join("\n")
    end

    def script_urls(*args)
      unless site.model.mapper.editable?
        begin
          ::Simultaneous.send_event('publish_progress', {:state => "compiling assets", :progress => "*"}.to_json)
        rescue Errno::ECONNREFUSED
        rescue Errno::ENOENT
        end
      end
      options = args.extract_options!
      options.update(:development => development?)
      _asset_environment.js(args.flatten, options)
    end

    alias_method :script, :scripts

    def script_tag(src)
      %(<script type="text/javascript" src="#{src}"></script>)
    end

    Spontaneous::Output::Helpers.register_helper(self, :html)
  end
end
