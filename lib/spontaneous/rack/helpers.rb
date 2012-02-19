# encoding: UTF-8

module Spontaneous
  module Rack
    module Helpers

      def style_url(style)
        "#{NAMESPACE}/css/#{style}.css"
      end

      def script_url(script)
        "#{NAMESPACE}/js/#{script}.js"
      end

      def script_list(scripts)
        # if Spontaneous.development?
          scripts.map do |script|
            src = "/js/#{script}.js"
            path = Spontaneous.application_dir(src)
            size = File.size(path)
            ["#{NAMESPACE}#{src}", size]
            # %(<script src="#{NAMESPACE}/js/#{script}.js" type="text/javascript"></script>)
          end.to_json
        # else
          # script bundling + compression
        # end
      end
    end
  end
end

