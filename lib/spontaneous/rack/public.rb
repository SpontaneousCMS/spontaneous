# encoding: UTF-8


module Spontaneous
  module Rack
    class Public
      include Sinatra::Helpers

      METHOD_GET = "GET".freeze
      METHOD_POST = "POST".freeze
      METHOD_HEAD = "HEAD".freeze
      HEADER_CONTENT_LENGTH = "Content-Length".freeze

      attr_reader :response, :request
      attr_accessor :page

      def initialize
      end

      def call(env)
        @response = ::Rack::Response.new
        @request = ::Rack::Request.new(env)
        find_page!

        response = catch(:halt) do
          case @request.request_method
          when METHOD_GET
            get
          else
            post
          end
        end

        parse_response(response)
        status, header, body = @response.finish


        # Never produce a body on HEAD requests. Do retain the Content-Length
        # unless it's "0", in which case we assume it was calculated erroneously
        # for a manual HEAD response and remove it entirely.
        if request.request_method == METHOD_HEAD
          body = []
          header.delete(HEADER_CONTENT_LENGTH) if header[HEADER_CONTENT_LENGTH] == '0'
        end

        [status, header, body]
      end

      def halt(*response)
        response = response.first if response.length == 1
        throw :halt, response
      end



      # stolen from Sinatra
      def parse_response(response)
        case
        when response.respond_to?(:spontaneous_content?)
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
      ACTION = "/#{S::Plugins::Controllers::ACTION_SEPARATOR}".freeze

      def show(page, status=200)
        page = Spontaneous::Site[page] if String === page
        @page = page
        status(status)
      end

      def redirect(redirection, redirect_code=:temporary)
        redirection = Spontaneous::Site[redirection] if String === redirection
        redirect_code = REDIRECTS[redirect_code] if Symbol === redirect_code
        redirect_code ||= REDIRECTS[:temporary]
        # let Sinatra's helper method set up the Location headers for us
        catch(:halt) { super(redirection.path) }
        status(redirect_code)
        # then re-throw the :halt
        halt
      end

      def content_type(type, params={})
        default = params.delete :default
        mime_type = mime_type(type) || default
        fail "Unknown media type: %p" % type if mime_type.nil?
        mime_type = mime_type.dup
        unless params.include? :charset# or settings.add_charset.all? { |p| not p === mime_type }
          params[:charset] = params.delete('charset')# || settings.default_encoding
        end
        mime_type << ";#{params.map { |kv| kv.join('=') }.join(', ')}" unless params.empty?
        response['Content-Type'] = mime_type
      end

      def find_page!
        @path, @format, @action = parse_path
        @page = Site[@path]
      end

      def format
        @format
      end

      def action
        @action
      end

      def get
        return not_found! unless @page

        @format = (@format || @page.default_format).to_sym if @page

        if @action
          status, headers, result = @page.process_action(action, request.env, format)
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
          block = page.request_block(request)
          parse_response(instance_eval(&block)) if (block)

          @format = (@format || @page.default_format).to_sym if @page
          render_page_with_format(@page, @format)
        end
      end

      # non-action urls shouldn't respond to post requests
      def post
        return not_found! unless @page
        block = page.request_block(request)
        return not_found! unless (block or action)

        if @action
          status, headers, result = page.process_action(action, request.env, format)
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
          parse_response(instance_eval(&block)) if (block)

          @format = (@format || @page.default_format).to_sym if @page
          render_page_with_format(@page, @format)
        end
        # our 404 page should come from the CMS
      end

      def parse_path
        path = request.path_info
        if path =~ %r(#{ACTION})
          path, action = path.split(ACTION)
          action, format = action.split(DOT)
        else
          path, format = path.split(DOT)
        end
        # format = (format || :html).to_sym
        [path, format, action]
      end

      def render_page_with_format(page, format)
        if page && page.provides_format?(format)
          content_type(page.mime_type(format))
          render_page(page, format)
        else
          # perhaps we should return the html version if the page exists but
          # doesn't respond to the requested format?
          # or even redirect to the html?
          not_found!
        end
      end
      def render_page(page, format = :html, local_params = {})
        response.body = page.render(format, local_params.merge({
          :params => request.params,
          :request => request,
          :session => request.session
        }))
      end

      REDIRECTS = {
        :permanent => 301,
        :temporary => 302
      }

      def redirect?(page)
        redirection, redirect_code = page.request_redirect(request.params, request, request.session)
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
