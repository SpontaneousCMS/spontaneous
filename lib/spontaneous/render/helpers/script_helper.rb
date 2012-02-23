# encoding: UTF-8

module Spontaneous::Render::Helpers
  module ScriptHelper
    Compression = Spontaneous::Render::Assets::Compression unless defined?(Compression)

    extend self

    def scripts(*args)
      scripts = args.flatten
      return compressed_scripts(scripts) if live?
      scripts.map do |script|
        script_tag(script)
      end.join("\n")
    end

    def script_tag(src)
        %(<script type="text/javascript" src="#{src}.js"></script>)
    end

    def compressed_scripts(scripts)
      file_paths = scripts.map { |script| find_file "#{script}.js" }
      compressed, hash = Compression.compress_js(file_paths)
      output_path = Spontaneous::Render.asset_path(revision) / "#{hash}.js"
      FileUtils.mkdir_p(File.dirname(output_path))
      File.open(output_path, "w") do |file|
        file.write(compressed)
      end
      script_tag("/rev/#{hash}")
    end

    def find_file(relative_path)
      ::Spontaneous.instance.paths.expanded(:public).map do |path|
        path / relative_path
      end.detect do |path|
        ::File.exist?(path)
      end
    end

    alias_method :script, :scripts
  end
end

