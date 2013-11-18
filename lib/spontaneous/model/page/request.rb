# encoding: UTF-8

module Spontaneous::Model::Page
  module Request
    extend Spontaneous::Concern

    # liked this but it didn't work particularly well so wasn't used in the end
    # perhaps, when I re-write the bloody Public handler i can use it
    class PageResponse
      attr_reader :page, :format, :request, :response

      def initialize(page, request, response, format)
        @page, @request, @response, @format = page, request, response, format
      end

      def headers(hash=nil)
        response.headers.merge! hash if hash
        response.headers
      end

      def session; request.session; end
      def params;  request.params; end



      def call(&block)
        response = catch(:halt) { instance_eval(&block) }
        case response
        when String
          [200, Spontaneous::Site[response]]
        when (100..599) === response
          [response, page]
        else
          response
        end
      end

      REDIRECTS = {
        :permanent => 301,
        :temporary => 302
      }

      def redirect(redirection, redirect_code=:temporary)
        redirection = Spontaneous::Site[redirection] if String === redirection
        redirect_code = REDIRECTS[redirect_code] if Symbol === redirect_code
        redirect_code ||= REDIRECTS[:temporary]
        throw(:halt, [redirect_code, redirection])
      end

      def show(page, status_code = 200)
        page = Spontaneous::Site[page] if String === page
        throw(:halt, [status_code, page])
      end
    end


    module ClassMethods
      def request(method = :get, &block)
        request_blocks[method.to_sym] = block
      end

      def request_blocks
        @request_blocks ||= supertype_request_blocks
      end

      def supertype_request_blocks
        supertype && supertype.respond_to?(:request_blocks) ? supertype.request_blocks.dup : {}
      end


      METHOD_MAP = {"GET" => :get, "POST" => :post, "PUT" => :put, "DELETE" => :delete, "HEAD" => :head }.freeze

      # Translate Rack's uppercase string methods to the symbols used internally
      def normalize_method(method)
        return method if method.is_a?(Symbol)
        METHOD_MAP[method]
      end

      # Tests for existance of a request handler for a method
      # Used by the publishing mechanism to determine which template bucket a
      # published page should be placed in.
      def dynamic?(method = :get)
        method = normalize_method(method)
        request_blocks.has_key?(method) && !request_blocks[method].nil?
      end

      # unused at present
      def _request_response(instance, request, response, format)
        method = request.request_method.downcase.to_sym
        if (block = request_blocks[method])
          app = PageResponse.new(instance, request, response, format)
          app.call(&block)
        else
          nil
        end
      end
    end # ClassMethods


    def request_block(request)
      method = request.request_method.downcase.to_sym
      self.class.request_blocks[method]
    end

    def dynamic?(method = :get)
      self.class.dynamic?(method)
    end
  end # Request
end
