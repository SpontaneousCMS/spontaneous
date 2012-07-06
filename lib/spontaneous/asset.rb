require 'sprockets'
require 'uglifier'
require 'sass'

module Spontaneous
  module Asset
    autoload :Source, "spontaneous/asset/source"
    autoload :File,   "spontaneous/asset/file"

    # Takes assets from a source directory & compiles them to some destination directory.
    # This is deliberatly dumb about the path to the
    class AppCompiler
      attr_reader :environment, :manifest

      def initialize(gem_path, dest_path, options = {})
        @options     = {:compress => true}.merge(options)
        @gem_path    = gem_path
        @dest_path   = dest_path
        @environment = Sprockets::Environment.new(gem_path / "application" )
        @manifest    = Sprockets::Manifest.new(@environment, @dest_path / "public/@spontaneous/assets")

        @environment.append_path(gem_path / "application/js")
        @environment.append_path(gem_path / "application/css")

        if @options[:compress]
          @environment.register_bundle_processor "application/javascript", :uglifier do |context, data|
            Uglifier.compile(data)
          end

          @environment.register_bundle_processor "text/css", :sass_compressor do |context, css|
            # By this point the SCSS has already been compiled, so SASS is merely a CSS compressor
            # and I can ignore crap around loadpaths or filenames.
            engine = ::Sass::Engine.new(css, :style => :compressed, :syntax => :scss, :quiet => true, :custom => { :resolver => self })
            engine.render
          end
        end
      end


      def compile
        # @environment.each_logical_path.select { |path| path =~ /^static/ }.each do |path|
        #   puts path
        #   # @manifest.compile(path)
        # end

        @manifest.compile("spontaneous.js", "login.js", "require.js", "vendor/jquery.js", "spontaneous.css")
      end

      def image_path(path)
        path
      end
    end
  end
end
module Spontaneous
  module Sass
    module Helpers
      def image_url(asset)
        ::Sass::Script::String.new "url(" + resolver.image_path(asset.value) + ")"
      end

      def resolver
        p options#[:quiet]
        options[:custom][:resolver]
      end
    end
  end
end
module Sass
  module Script
    module Functions
      include Spontaneous::Sass::Helpers
    end
  end
end
