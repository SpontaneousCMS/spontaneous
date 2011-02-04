# encoding: UTF-8


module Spontaneous
  module Rack
    class Public < ServerBase
      set :static, true
      set :public, Proc.new { Spontaneous.root / "public" }

      # see http://benprew.posterous.com/testing-sessions-with-sinatra
      if test?
        set :sessions, false
      else
        set :sessions, true
      end


      get "/" do
        Site.root.render
      end

      get '/media/*' do
        send_file(Spontaneous.media_dir / params[:splat].first)
      end

      DOT = '.'.freeze

      get "*" do
        path, format = params[:splat].first.split(DOT)
        page = Site[path]
        return not_found! unless page
        if destination = redirect?(page)
          redirect(*destination)
        else
          if show = page.show(params, request, session)
            case show
            when String
              page = Site[show]
            else
              page = show
            end
          end

          if page && page.provides_format?(format)
            content_type(::Rack::Mime.mime_type("#{DOT}#{format}")) if format
            page.render(format, {
              :params => params,
              :request => request,
              :session => session
            })
          else
            # perhaps we should return the html version if the page exists but
            # doesn't respond to the requested format?
            # or even redirect to the html?
            not_found!
          end
        end
      end

      REDIRECTS = {
        :permanent => 301,
        :temporary => 302
      }

      def redirect?(page)
        redirection, redirect_code = page.redirect(params, request, session)
        if redirection
          redirection = redirection.path if redirection.respond_to?(:path)
          redirect_code = REDIRECTS[redirect_code] if Symbol === redirect_code
          redirect_code ||= REDIRECTS[:temporary]
          [redirection.to_s, redirect_code]
        else
          nil
        end
      end

      def not_found!
        404
      end
    end
  end
end

