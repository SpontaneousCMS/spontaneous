# encoding: UTF-8

module Spontaneous::Render::Helpers
  module ScriptHelper
    extend self

    def scripts(*args)
      scripts = args.flatten
      return compressed_scripts(scripts) if live?
      scripts.map { |script| script_tag(script)  }.join("\n")
    end

    alias_method :script, :scripts

    def script_tag(src)
      src = "#{src}.js" unless src =~ /\.js$/o
      %(<script type="text/javascript" src="#{src}"></script>)
    end

    def compressed_scripts(scripts)
      file_paths = scripts.map { |script| [script, find_file("#{script}.js")] }
      invalid, file_paths = file_paths.partition { |url, path| path.nil? }
      tags = []
      unless file_paths.empty?
        compressed, hash = Spontaneous::Render::Assets.compress_js(file_paths.map(&:last))
        output_path = Spontaneous::Render::Assets.path_for(revision, "#{hash}.js")

        FileUtils.mkdir_p(File.dirname(output_path))
        File.open(output_path, "w") { |file| file.write(compressed) }

        tags = [script_tag(Spontaneous::Render::Assets.url(hash))]
      end
      tags.concat invalid.map { |src, path| script_tag(src) }
      tags.join("\n")
    end

    def find_file(relative_path)
      Spontaneous.instance.paths.expanded(:public).each do |root|
        path = root / relative_path
        return path if ::File.exist?(path)
      end
      nil
    end
  end
end

