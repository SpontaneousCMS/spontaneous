# encoding: UTF-8

require 'coffee-script'

module Spontaneous::Rack
  class JS
    JS_EXTENSION = /\.js$/o

    def initialize(app, options = {})
      @roots = options[:root]
      @app = app
    end

    def call(env)
      try_coffeescript(env[S::PATH_INFO]) or @app.call(env)
    end

    def try_coffeescript(request_path)
      return nil unless request_path =~ JS_EXTENSION
      try_paths = @roots.map { |root| File.join(root, request_path) }
      # if the css file itself exists then we want to use that
      return nil if try_paths.detect { |file| ::File.exists?(file) }

      try_paths.each do |path|
        template = template_path(path)
        return render_coffeescript(template) if File.exists?(template)
      end
      # tried all the possible sass templates and haven't found one that matches
      # the requested css file
      raise Sinatra::NotFound
    end

    def render_coffeescript(template)
      script = CoffeeScript.compile(File.read(template))
      [200, {'Content-type' => 'text/css'}, StringIO.new(script)]
    end

    def template_path(path)
      path.gsub(JS_EXTENSION, ".coffee")
    end
  end
end

