# encoding: UTF-8


module Spontaneous
  module Rack
    class Public < ServerBase
      # use ::Rack::Reloader if Spontaneous::Config.reload_classes
      use Reloader if Spontaneous::Config.reload_classes
      # set :static, true
      # set :public, Proc.new { Spontaneous.root / "public" }

      # get '/media/*' do
      #   send_file(Spontaneous.media_dir / params[:splat].first)
      # end

      get "/" do
        render_page(Site.root)
      end

      DOT = '.'.freeze
      ACTION = "/#{S::Plugins::Actions::ACTION_SEPARATOR}".freeze

      get "*" do
        path, format, action = parse_path
        page = Site[path]
        return not_found! unless page
        if destination = redirect?(page)
          redirect(*destination)
        else
          if show = page.request_show(params, request, session)
            case show
            when String
              page = Site[show]
            else
              page = show
            end
          end

          if action
            status, headers, result = page.process_action(action, env, format)
            # our 404 page should come from the CMS
            if status == 404
              not_found!
            else
              if result.respond_to?(:spontaneous_content?)
                render_page_with_format(result, format)
              else
                [status, headers, result]
              end
            end
          else
            render_page_with_format(page, format)
          end
        end
      end

      # non-action urls shouldn't respond to post requests
      post "*" do
        path, format, action = parse_path
        return not_found! unless action
        page = Site[path]
        return not_found! unless page
        status, headers, result = page.process_action(action, env, format)
        # our 404 page should come from the CMS
        if status == 404
          not_found!
        else
          if result.respond_to?(:spontaneous_content?)
            render_page_with_format(result, format)
          else
            [status, headers, result]
          end
        end
      end

      def parse_path
        path = params[:splat].first
        if path =~ %r(#{ACTION})
          path, action = path.split(ACTION)
          action, format = action.split(DOT)
        else
          path, format = path.split(DOT)
        end
        format = (format || :html).to_sym
        [path, format, action]
      end

      def render_page_with_format(page, format)
          if page && page.provides_format?(format)
            content_type(::Rack::Mime.mime_type("#{DOT}#{format}")) if format
            render_page(page, format)
          else
            # perhaps we should return the html version if the page exists but
            # doesn't respond to the requested format?
            # or even redirect to the html?
            not_found!
          end
      end
      def render_page(page, format = :html, local_params = {})
        page.render(format, local_params.merge({
          :params => params,
          :request => request,
          :session => session
        }))
      end

      REDIRECTS = {
        :permanent => 301,
        :temporary => 302
      }

      def redirect?(page)
        redirection, redirect_code = page.request_redirect(params, request, session)
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

