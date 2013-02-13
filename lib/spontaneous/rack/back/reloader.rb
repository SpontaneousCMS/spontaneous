# encoding: UTF-8

require 'stringio'
require 'erubis'
require 'tilt'

module Spontaneous::Rack::Back
  class Reloader
    include Spontaneous::Rack::Back::TemplateHelpers

    def initialize(app, *args)
      @app      = app
      @active   = Spontaneous::Site.config.reload_classes
      config    = args.first || {}
      @cooldown = config[:cooldown] || 3
      @last     = (Time.now - @cooldown)
    end

    def call(env)
      reload if should_reload?
      @app.call(env)
    rescue Spontaneous::SchemaModificationError => error
      schema_conflict!(env, error)
    end

    def should_reload?
      @active && @cooldown && (Time.now > (@last + @cooldown))
    end

    def reload
      if Thread.list.size > 1
        Thread.exclusive{ reload! }
      else
        reload!
      end
      @last = Time.now
    end

    def reload!
      Spontaneous.reload!
    end

    def schema_conflict!(env, error)
      template_path = ::File.expand_path('../../../../../application/views/schema_modification_error.html.erb', __FILE__)
      template = Tilt::ErubisTemplate.new(template_path)
      html = template.render(self, :modification => error.modification, :env => env)
      [412, {'Content-type' => ::Rack::Mime.mime_type('.html')}, StringIO.new(html)]
    end
  end
end
