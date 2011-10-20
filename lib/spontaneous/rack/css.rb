# encoding: UTF-8

require 'sass'

module Spontaneous::Rack
  class CSS
    def initialize(app, options = {})
      @options = options
      @root = options.delete(:root)
      @app = app
    end

    def call(env)
      path = env[S::PATH_INFO]
      if path =~ /\.css$/ and !File.exists?(File.join(@root, path))
        template = template_root_path(path) + ".scss"
        if File.exists?(template)
          load_paths = [Spontaneous.css_dir, File.dirname(template), File.join(File.dirname(template), "sass")]
          engine = Sass::Engine.for_file(template, {
            :load_paths => load_paths,
            :filename => template,
            :cache => false,
            :style => :expanded
          })
          [200, {'Content-type' => 'text/css'}, [engine.render]]
        else
          raise Sinatra::NotFound
        end
      else
        @app.call(env)
      end
    end

    def template_root_path(path)
      basename = File.basename(path, '.css')
      File.join(@root, File.dirname(path), basename)
    end
  end
end
