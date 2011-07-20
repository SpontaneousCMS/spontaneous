# encoding: UTF-8

require 'stringio'
require 'erubis'
require 'tilt'

module Spontaneous
  module Rack
    class Reloader
      def initialize(app)
        @app = app
        @cooldown = 3
        @last = (Time.now - @cooldown)
      end


      def call(env)
        if @cooldown and Time.now > @last + @cooldown
          if Thread.list.size > 1
            Thread.exclusive{ reload! }
          else
            reload!
          end

          @last = Time.now
        end

        @app.call(env)
      rescue Spontaneous::SchemaModificationError => error
        template = Tilt::ErubisTemplate.new(File.expand_path('../../../../application/views/schema_modification_error.html.erb', __FILE__))
        html = template.render(error.modification, :env => env)
        [412, {'Content-type' => ::Rack::Mime.mime_type('.html')}, StringIO.new(html)].tap do |response|
        end
      end

      def reload!
        Spontaneous.reload!
      end
    end # Reloader
  end # Rack
end # Spontaneous

