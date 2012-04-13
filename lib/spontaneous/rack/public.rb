# encoding: UTF-8


module Spontaneous
  module Rack
    module Public
      include HTTP
      include Sinatra::Helpers unless method_defined?(:redirect)



      attr_reader :env, :response, :request
      attr_accessor :page

      def render_path(path)
        find_page!(path)

        response = catch(:halt) do
          if @page
            case @request.request_method
            when METHOD_GET
              render_get
            else
              render_post
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

      def halt(*response)
        response = response.first if response.length == 1
        throw :halt, response
      end



      # stolen from Sinatra
      def parse_response(response)
        case
        when response.is_a?(Spontaneous::Content)
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

      REDIRECTS = {
        :permanent => 301,
        :temporary => 302
      }

      def redirect(location, redirect_code=:temporary)
        if String === location
          destination = Site[location]
          location = destination.path if destination and destination.respond_to?(:path)
        else
          location = location.path if location.respond_to?(:path)
        end
        redirect_code = REDIRECTS[redirect_code] if Symbol === redirect_code
        redirect_code ||= REDIRECTS[:temporary]
        # let Sinatra's helper method set up the proper Location headers for us
        catch(:halt) { super(location) }
        status(redirect_code)
        # then re-throw the :halt
        halt
      end

      def content_type(type, params={})
        default = params.delete :default
        mime_type = mime_type(type) || default
        fail "Unknown media type: %p" % type if mime_type.nil?
        mime_type = mime_type.dup
        unless params.include? :charset
          params[:charset] = params.delete('charset') || ::Spontaneous.config.default_charset || 'utf-8'
        end
        mime_type << ";#{params.map { |kv| kv.join('=') }.join(', ')}" unless params.empty?
        response['Content-Type'] = mime_type
      end

      def find_page!(path)
        @path, @output, @action = parse_path(path)
        @page = Site[@path]
      end

      def output
        @output
      end

      def action
        @action
      end

      def render_get
        if @action
          call_action!
        else
          block = page.request_block(request)
          parse_response(instance_eval(&block)) if (block)
          render_page_with_output
        end
      end

      # non-action urls shouldn't respond to post requests
      def render_post
        block = page.request_block(request)
        return not_found! unless (block or @action)

        if @action
          call_action!
        else
          parse_response(instance_eval(&block)) if (block)
          render_page_with_output
        end
      end

      def call_action!
        status, headers, result = @page.process_action(action, request.env, output)
        if status == 404
          not_found!
        else
          if result.is_a?(Spontaneous::Content)
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
        return not_found! if     @page.nil?
        return not_found! unless @page.provides_output?(@output)

        output = @page.output(@output)

        if output.public?
          content_type(output.mime_type)
          render_page(@page, output)
        else
          not_found!
        end
      end

      def render_page(page, output, local_params = {})
        response.body = output.render(local_params.merge({
          :params => request.params,
          :request => request,
          :session => request.session
        }))
      end

      # our 404 page should come from the CMS
      def not_found!
        404
      end
    end
  end
end
