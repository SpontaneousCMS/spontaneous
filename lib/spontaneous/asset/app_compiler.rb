require 'sprockets'
require 'uglifier'
require 'sass'

module Spontaneous::Asset
  # Takes assets from a source directory & compiles them to some destination directory.
  # This is deliberatly dumb about the path to the gem and destination
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
          engine = ::SassC::Engine.new(css, :style => :compressed, :syntax => :scss, :quiet => true, :custom => { :resolver => self })
          engine.render
        end
      end
    end


    def compile
      @manifest.compile("spontaneous.js", "login.js", "require.js", "vendor/jquery.js", "spontaneous.css")
    end

    def image_path(path)
      path
    end
  end
end
