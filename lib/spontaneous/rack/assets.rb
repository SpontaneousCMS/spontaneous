# encoding: UTF-8

require 'shine'
require 'sass'

module Spontaneous
  module Rack
    module Assets

      # module Bundling
      #   extend self

      #   def compress_js(filelist, options={})
      #     shine_compress_files(filelist, :js, options)
      #   end

      #   def compress_css(filelist, options={})
      #     # compress_files(filelist, :css, options)
      #     options = {
      #       :load_paths => [Spontaneous.css_dir],
      #       # :filename => sass_template,
      #       :cache => false,
      #       :style => :compressed
      #     }
      #     paths = paths(filelist)
      #     css = paths.map do |path|
      #       Sass::Engine.for_file(path, options).render
      #     end.join("\\n")
      #     hash = digest(css)
      #     [css, hash]
      #   end

      #   def shine_compress_files(filelist, format, options = {})
      #     paths = paths(filelist)
      #     original_size = filesize(paths)
      #     compressed = Shine::compress_files(paths, format, options)
      #     logger.info("Compressed #{filelist.length} files. Original size #{original_size}, compressed size #{compressed.length}, ratio #{(100*compressed.length.to_f/original_size.to_f).round}%")
      #     hash = digest(compressed)
      #     [compressed, hash]
      #   end

      #   def digest(str)
      #     hash = Digest::SHA1.new.update(str).hexdigest
      #   end

      #   def paths(filelist)
      #     filelist.map { |file| filepath(file) }.tap do |paths|
      #       logger.info("Bundling #{paths.length} files")
      #     end
      #   end

      #   def filepath(file)
      #     File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
      #   end

      #   def filesize(paths)
      #     paths.inject(0) { |sum, path| sum += File.size(path) }
      #   end
      # end
      module JavaScript
        extend Spontaneous::Output::Assets::Compression

        def self.filetype
          "js"
        end

        def self.extension
          "js"
        end

        def self.compress(filelist)
          compress_js(paths(filelist))
        end

        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        # TODO: remove these
        JQUERY = %w(vendor/jquery)
        COMPATIBILITY = []#%w(compatibility)
        REQUIRE = %w(require)
        LOGIN_JS = %w(login)
        EDITING_JS = %w(spontaneous)
      end

      module CSS
        extend Spontaneous::Output::Assets::Compression

        def self.filetype
          "css"
        end
        def self.extension
          "scss"
        end

        def self.compress(filelist)
          compress_css(paths(filelist))
        end


        def paths(filelist)
          filelist.map { |file| filepath(file) }.tap do |paths|
            logger.info("Bundling #{paths.length} files")
          end
        end

        def filepath(file)
          File.join(Spontaneous.application_dir, filetype, "#{file}.#{extension}")
        end

        # TODO: remove these
        LOGIN_CSS = %w(spontaneous) # login
        EDITING_CSS = %w(spontaneous)
        SCHEMA_MODIFICATION_CSS = %w(spontaneous) #schema_error
      end

    end # Assets
  end # Rack
end # Spontaneous
