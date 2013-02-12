require 'sass'
require 'uglifier'

module Spontaneous
  module Output
    module Assets
      module Compression
        extend self

        def compress_js_files(filelist, options = {})
          js = []
          compressor = js_compressor(options)
          filelist.each do |path|
            ::File.open(path, "rb") do |source|
              js << compressor.compile(source)
            end
          end
          compressed = js.join("\n")
          [compressed, digest(compressed)]
        end

        def compress_js_string(source, options = {})
          compressed = compress_js(source, options)
          [compressed, digest(compressed)]
        end

        def compress_js(source, options = {})
          js_compressor(options).compile(source)
        end

        def js_compressor(options = {})
          Uglifier.new(options.merge(default_js_compression_options))
        end

        # Default options passed to Uglifier
        # an empty hash means "accept defaults"
        def default_js_compression_options
          {}
        end

        def compress_css_files(filelist, options={})
          opts = {
            :load_paths => [Spontaneous.css_dir],
            :cache => false,
            :style => :compressed
          }.merge(options)
          css = filelist.map do |path|
            Sass::Engine.for_file(path, opts).render
          end.join("\n")
          hash = digest(css)
          [css, hash]
        end

        def compress_css_string(source)
          compressed = compress_css(source)
          [compressed, digest(compressed)]
        end

        def compress_css(source)
          opts = { :cache => false, :style => :compressed, :syntax => :scss }
          Sass::Engine.new(source, opts).render
        end

        def digest(str)
          hash = Digest::SHA1.new.update(str).hexdigest
        end


        def filesize(paths)
          paths.compact.inject(0) { |sum, path| sum += File.size(path) }
        end
      end
    end
  end
end
