# encoding: UTF-8

require 'sass'

module Spontaneous::Rack
  class CSS
    CSS_EXTENSION = /\.css$/o

    def initialize(app, options = {})
      @roots = options[:root]
      @app = app
    end

    def call(env)
      try_sass(env[S::PATH_INFO]) or @app.call(env)
    end

    def try_sass(request_path)
      return nil unless request_path =~ CSS_EXTENSION
      try_paths = @roots.map { |root| File.join(root, request_path) }
      # if the css file itself exists then we want to use that
      return nil if try_paths.detect { |file| ::File.exists?(file) }

      try_paths.each do |path|
        template = template_path(path)
        return render_sass_template(template) if File.exists?(template)
      end
      nil
    end

    def render_sass_template(template)
      load_paths = [Spontaneous.css_dir, File.dirname(template), File.join(File.dirname(template), "sass")]
      engine = Sass::Engine.for_file(template, {
        :load_paths => load_paths,
        :filename => template,
        :cache => false,
        :style => :expanded
      })
      [200, {'Content-type' => 'text/css'}, [engine.render]]
    end

    def template_path(path)
      path.gsub(CSS_EXTENSION, ".scss")
    end
  end
end
