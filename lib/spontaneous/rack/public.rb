# encoding: UTF-8


module Spontaneous
  module Rack
    module Public
      include Constants
      # include Sinatra::Helpers unless method_defined?(:redirect)

      attr_reader :env, :response, :request
      attr_accessor :page

      def render_path(path)
        @template_params = {}
        find_page!(path)

        response = catch(:halt) do
          if @page
            case @request.request_method
            when METHOD_GET, METHOD_HEAD
              render_get
            else
              render_other
            end
          else
            not_found!
          end
        end

        parse_response(response)
        status, header, body = @response.finish

        # Never produce a body on HEAD requests. Do retain the Content-Length
        # unless it's "0", in which case we assume it was calculated erroneously
        # for a manual HEAD response and remove it entirely.
        if request.request_method == METHOD_HEAD
          body = []
          header.delete(HTTP_CONTENT_LENGTH) if header[HTTP_CONTENT_LENGTH] == '0'
        end

        [status, header, body]
      end

      # stolen from Sinatra
      def parse_response(response)
        case
        when response.is_a?(site.model)
          @page = response
        when response.respond_to?(:to_str)
          @response.body = [response]
        when response.respond_to?(:to_ary)
          response = response.to_ary
          if Fixnum === response.first
            if response.length == 3
              @response.status, headers, body = response
              @response.body = body if body
              headers.each { |k, v| @response.headers[k] = v } if headers
            elsif response.length == 2
              @response.status = response.first
              @response.body   = response.last
            else
              raise TypeError, "#{response.inspect} not supported"
            end
          else
            @response.body = response
          end
        when response.respond_to?(:each)
          @response.body = response
        when (100..599) === response
          @response.status = response
        end
      end

      DOT = '.'.freeze
      ACTION = "/#{S::Model::Page::Controllers::ACTION_SEPARATOR}".freeze

      def content_type(type, params={})
        default   = params.delete :default
        mime_type = mime_type(type) || default
        fail "Unknown media type: %p" % type if mime_type.nil?
        mime_type = mime_type.dup
        unless params.include? :charset
          params[:charset] = params.delete('charset') || site.config.default_charset || 'utf-8'
        end
        mime_type << ";#{params.map { |kv| kv.join('=') }.join(', ')}" unless params.empty?
        response['Content-Type'] = mime_type
      end

      def find_page!(path)
        @controller_path = SLASH
        @path, @output, @action = parse_path(path)
        @page = find_page_by_path(@path)
      end

      def find_page_by_path(path)
        with_scope { site.by_path(path)  || find_page_with_wildcards(path) }
      end

      # if we get to here it's because the path hasn't been found. This will get called for
      # every request where the request doesn’t resolve to a path found in the db
      # and will always try the site homepage as a last resort. So if you need many dynamic
      # routes to resolve to a single page, e.g. for a single page app, then you just
      # need to accept all those routes in a controller on the class of the site’s homepage
      # and render your SPA template from that, e.g.
      #
      #     class Homepage < Page
      #       controller do
      #         get '/app*' do
      #           render
      #         end
      #       end
      #     end
      #
      def find_page_with_wildcards(path)
        parts = path.split('/')
        length = parts.length - 2
        range = (1..length).to_a.reverse

        # make sure we go all the way back to the site homepage
        try = range.map { |l| parts[0..l].join(SLASH) }.push(SLASH)
        candidate = site.model::Page.where(path: try).order(Sequel.desc(:depth)).first
        return nil if candidate.nil? || !candidate.dynamic?(request.request_method)

        # don't pass the full path of the request to the controller, just
        # the bit after the candidate page’s path.
        cpath = candidate.path
        @controller_path = path.slice(cpath.length, path.length - cpath.length)

        # special handling of root, as always so that a controller on the root page that
        # matches '/', e.g. `get '/'` is passed a path that starts with '/'
        if cpath == SLASH
          @controller_path.insert(0, SLASH)
        end

        candidate
      end

      def output(name)
        @output = name.to_s
      end

      def action
        @action
      end

      def render_get
        return call_action! if @action
        if page.dynamic?(request.request_method)
          invoke_action { page.process_root_action(site, env_for_action, @output) }
        else
          render_page_with_output
        end
      end

      # Only pages that provide a controller for the current URL should respond
      # to anything other than GET or HEAD
      def render_other
        return not_found! unless (page.dynamic?(request.request_method) or @action)

        return call_action! if @action

        invoke_action { page.process_root_action(site, env_for_action, @output) }
      end

      def call_action!
        invoke_action { @page.process_action(site, action, env_for_action, @output) }
      end

      def env_for_action
        env.merge(S::Constants::PATH_INFO => @controller_path)
      end

      def invoke_action
        status, headers, result = yield
        if status == 404
          not_found!
        else
          if result.is_a?(site.model)
            @page = result
            render_page_with_output
          else
            [status, headers, result]
          end
        end
      end

      def parse_path(path)
        if path =~ %r(#{ACTION})
          path, action = path.split(ACTION)
          path = "/" if path.empty?
          action, format = action.split(DOT)
        else
          path, format = path.split(DOT)
        end
        [path, format, action]
      end

      def render_page_with_output
        _render_page_with_output(@page, @output, @template_params)
      end

      def _render_page_with_output(page, output, template_params)
        return not_found! if     page.nil?
        return not_found! unless page.provides_output?(output)

        output = page.output(output)

        if output.public?
          content_type(output.mime_type)
          render_page(page, output, template_params)
        else
          not_found!
        end
      end

      def renderer
        env[Rack::RENDERER]
      end

      def render_page(page, output, local_params = {})
        response.body = output.render_using(renderer, local_params.merge({
          :params  => params, # use sinatras indifferent params
          :request => request,
          :session => request.session
        }))
      end

      # our 404 page should come from the CMS
      def not_found!
        404
      end

      def with_scope
        yield
      end
    end
  end
end
