require 'shine'
require 'sass'

module Spontaneous
  module Render
    module Assets
      module Compression
        extend self

        def compress_js(filelist, options={})
          shine_compress_files(filelist, :js, options)
        end

        def compress_css(filelist, options={})
          # compress_files(filelist, :css, options)
          options = {
            :load_paths => [Spontaneous.css_dir],
            # :filename => sass_template,
            :cache => false,
            :style => :compressed
          }
          css = filelist.map do |path|
            Sass::Engine.for_file(path, options).render
          end.join("\n")
          hash = digest(css)
          [css, hash]
        end

        def shine_compress_files(filelist, format, options = {})
          original_size = filesize(filelist)
          compressed = Shine::compress_files(filelist, format, options)
          logger.info("Compressed #{filelist.length} files. Original size #{original_size}, compressed size #{compressed.length}, ratio #{(100*compressed.length.to_f/original_size.to_f).round}%")
          hash = digest(compressed)
          [compressed, hash]
        end

        def digest(str)
          hash = Digest::SHA1.new.update(str).hexdigest
        end


        def filesize(paths)
          paths.inject(0) { |sum, path| sum += File.size(path) }
        end
      end
    end
  end
end
