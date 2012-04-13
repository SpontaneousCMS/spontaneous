# encoding: UTF-8

require 'coffee-script'

module Spontaneous::Render::Helpers
  module ScriptHelper
    extend self

    def scripts(*args)
      scripts = args.flatten
      options = scripts.extract_options!
      compress = (live? or (publishing? and options[:force_compression]))
      return compressed_scripts(scripts) if compress
      scripts.map { |script| script_tag(script)  }.join("\n")
    end

    alias_method :script, :scripts

    def script_tag(src)
      src = "#{src}.js" unless src =~ /\.js$/o
      %(<script type="text/javascript" src="#{src}"></script>)
    end

    def convert_coffeescript(url)
      S::Render::Assets.compile_coffeescript(url)
    end

    def compressed_scripts(scripts)
      file_paths = scripts.map { |script| [script, S::Render::Assets.find_file("#{script}.js", "#{script}.coffee")] }
      invalid, file_paths = file_paths.partition { |url, path| path.nil? }

      tags = []
      unless file_paths.empty?
        # in order to compile coffeescript efficiently, avoiding multiple anonymous function wrappers
        # but keeping the files in the correct order
        # first partition files into js & coffee groups:
        types = file_paths.slice_between { |(purl, ppath), (url, path)| File.extname(ppath) != File.extname(path) }
        # then iterate through each group to concatenate the source into a single string (src)
        js = types.map { |type|
          ext = nil
          src = type.map { |url, path|
            ext = File.extname(path)
            File.read(path)
          }.join
          # then compile the concatenated src if it's coffeescript
          case ext
          when ".coffee"
            CoffeeScript.compile src
          else
            src
          end
        }.join

        compressed, hash = compress_js_string(js)
        output_path = Spontaneous::Render::Assets.path_for(revision, "#{hash}.js")

        FileUtils.mkdir_p(File.dirname(output_path))
        File.open(output_path, "w") { |file| file.write(compressed) }

        tags = [script_tag(Spontaneous::Render::Assets.url(hash))]
      end

      tags.concat invalid.map { |src, path| script_tag(src) }
      tags.join("\n")
    end

    def compress_js_string(js_string)
      Spontaneous::Render::Assets::Compression.shine_compress_string(js_string, :js)
    end

    Spontaneous::Render::Helpers.register_helper(self, :html)
  end
end

