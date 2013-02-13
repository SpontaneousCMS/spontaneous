
module Spontaneous::Rack::Back
  module TemplateHelpers
    include Spontaneous::Rack::Constants

    def application_assets
      @application_assets_compiler ||= Spontaneous::Asset::AppCompiler.new(Spontaneous.gem_dir, Spontaneous.root)
    end

    def style_url(style)
      asset_url(style, "css")
    end

    def script_url(script)
      asset_url(script, "js")
    end

    def asset_url(file, type)
      file = "#{file}.#{type}" unless file =~ /\.#{type}$/


      if (compiled_asset = application_assets.manifest.assets[file])
        return "#{NAMESPACE}/assets/#{compiled_asset}"
      end
      # TODO: use the sprockets environment to append a modification time to the non-compiled URL
      "#{NAMESPACE}/#{type}/#{file}"
    end

    def script_list(scripts)
      scripts.map do |script|
        script = "#{script}.js" unless script =~ /\.js$/
        src = script_url(script)
        size = 0
        if (asset = application_assets.manifest.files[::File.basename(src)])
          size = asset["size"]
        else
          src = "#{NAMESPACE}/js/#{script}"
          path = Spontaneous.application_dir("/js/#{script}")
          size = ::File.size(path)
        end
        [src, size]
      end.to_json
    end
  end

  module Helpers
    include Spontaneous::Rack::Constants

    def json(response)
      content_type 'application/json', :charset => 'utf-8'
      response.serialise_http(user)
    end


    def forbidden!
      halt 403#, "You do not have the necessary permissions to update the '#{name}' field"
    end


    def api_key
      request.cookies[AUTH_COOKIE]
    end

    def user
      env[ACTIVE_USER]
    end

    def show_login_page(locals = {})
      halt(401, erb(:login, :views => Spontaneous.application_dir('/views'), :locals => locals))
    end
  end
end
