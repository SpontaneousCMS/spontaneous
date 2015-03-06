# encoding: UTF-8

require 'sinatra/base'

module Spontaneous::Rack
  class PageController < Sinatra::Base
    class << self
      # We wrap Sinatra's route methods in order to do two things:
      #   1. To provide a path of '*' when none is given and
      #   2. To register the presence of a handler for each method in order to
      #      correctly respond to the #dynamic? test
      def get(*args, &bk)     __dynamic!(:get,     super(*__route_args(args), &bk)) end
      def put(*args, &bk)     __dynamic!(:put,     super(*__route_args(args), &bk)) end
      def post(*args, &bk)    __dynamic!(:post,    super(*__route_args(args), &bk)) end
      def delete(*args, &bk)  __dynamic!(:delete,  super(*__route_args(args), &bk)) end
      def head(*args, &bk)    __dynamic!(:head,    super(*__route_args(args), &bk)) end
      def options(*args, &bk) __dynamic!(:options, super(*__route_args(args), &bk)) end
      def patch(*args, &bk)   __dynamic!(:patch,   super(*__route_args(args), &bk)) end
      def link(*args, &bk)    __dynamic!(:link,    super(*__route_args(args), &bk)) end
      def unlink(*args, &bk)  __dynamic!(:unlink,  super(*__route_args(args), &bk)) end

      def dynamic?(method = :get)
        __dynamic[method]
      end


      private

      def __route_args(args)
        opts = args.extract_options!
        path = (String === args.first) ? args.first : S::Constants::SLASH
        [path, opts]
      end

      def __dynamic!(method, action)
        __dynamic[method] = true
      end

      def __dynamic
        @__dynamic ||= {}
      end
    end

    attr_reader :content, :site

    def initialize(site, content, output)
      @site, @content, @output, @locals = site, content, output, {}
      @page = content.page
      super(nil)
    end

    # render [instance (Content), output (Symbol), status (Fixnum), locals (Hash)]
    # render [singleton name (Symbol), status (Fixnum), locals (Hash)] => [instance, output, status, locals]
    # render [singleton name (Symbol)]       => [singleton name, output, 200, {}]
    # render [instance (Content)] => [instance, output, 200, {}]
    # render [locals (Hash)] => [page, output, 200, locals]
    # render [status (Fixnum)] => [page, output, status, {}]
    # render(:home, :xml, 200, {logged_in: true}) # => :home => singleton name, :xml => output
    # render(:home, 200, {logged_in: true}) # => :home => singleton name
    # render(:home, {logged_in: true}) # => :home => singleton name
    # render(:xml, 200, {logged_in: true}) # NOT ALLOWED: if you want to specify the output then you must also specify the page
    # render(403, {logged_in: false})
    #
    # Every controller *must* include a call to render
    def render(*args)
      @locals = args.extract_options!
      show(*args)
      render_body
    end

    # Show provides a way to configure future calls to render without the overhead of
    # calling #render itself. Good if you want to set up a default state & then override
    # it later.
    # Only #render accepts a locals hash that is passed into the render call
    def show(*args)
      page, output, status = self.page, self.output, self.status
      case args.length
      when 3
        page, output, status = args
      when 2
        page, last = args
        case last
        when Fixnum
          status = last
        else
          output = last
        end
      when 1
        case (arg = args.first)
        when Fixnum
          status = arg
        else
          page = arg
        end
      end
      page(page)
      status(status)
      output(output)
    end


    REDIRECTS = {
      :permanent => 301,
      :temporary => 302
    }

    def redirect(location, redirect_code=:temporary)
      if String === location
        destination = @site[location]
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

    def output(*args)
      return @output if args.empty?
      @output = args.first
    end

    def not_found
      super(not_found_body)
    end

    def page(page = nil)
      return @page if page.nil?
      @page = fetch_page(page)
    end

    private

    def renderer
      env[Spontaneous::Rack::RENDERER]
    end

    def fetch_page(locator)
      case locator
      when Class # (singleton) type classes
        locator.first
      when Symbol, String
        fetch_singleton(locator) || fetch_path(locator)
      else # probably an instance
        locator
      end
    end

    def fetch_path(path)
      @site[path]
    end

    def fetch_singleton(page)
      return @site.send(page) if @site.singleton?(page)
      nil
    end

    def render_body
      body(render_page)
    end

    def render_page
      not_found if     page.nil?
      not_found unless page.provides_output?(self.output)
      output = page.output(self.output)
      render_output(output)
    end

    def render_output(output)
      if output.public?
        content_type(output.mime_type)
        do_render(output, @locals)
      else
        not_found
      end
    end

    def do_render(output, locals)
      locals = locals.merge({
        params: params, # use sinatras indifferent params
        request: request,
        session: request.session,
        env: request.env
      })
      output.render_using(renderer, locals)
    end

    def not_found_body
      "not found"
    end
  end
end
