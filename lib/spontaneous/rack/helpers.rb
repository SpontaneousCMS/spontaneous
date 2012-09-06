# encoding: UTF-8

require 'sprockets'

module Spontaneous
  module Rack
    module Helpers
      def json(response)
        content_type 'application/json', :charset => 'utf-8'
        response.serialise_http(user)
      end

      def application_assets
        @application_assets_compiler ||= Spontaneous::Asset::AppCompiler.new(Spontaneous.gem_dir, Spontaneous.root)
      end

      def style_url(style)
        style = "#{style}.css" unless style =~ /\.css$/
        if (compiled_asset = application_assets.manifest.assets[style])
          return "#{NAMESPACE}/assets/#{compiled_asset}"
        end
        # TODO: use the sprockets environment to append a modification time to the non-compiled URL
        "#{NAMESPACE}/css/#{style}"
      end

      def script_url(script)
        script = "#{script}.js" unless script =~ /\.js$/

        if (compiled_asset = application_assets.manifest.assets[script])
          return "#{NAMESPACE}/assets/#{compiled_asset}"
        end
        # TODO: use the sprockets environment to append a modification time to the non-compiled URL
        "#{NAMESPACE}/js/#{script}"
      end

      def script_list(scripts)
        scripts.map do |script|
          script = "#{script}.js" unless script =~ /\.js$/
          src = script_url(script)
          size = 0
          if (asset = application_assets.manifest.files[File.basename(src)])
            size = asset["size"]
          else
            src = "#{NAMESPACE}/js/#{script}"
            path = Spontaneous.application_dir("/js/#{script}")
            size = File.size(path)
          end
          [src, size]
        end.to_json
      end
    end
  end
end
