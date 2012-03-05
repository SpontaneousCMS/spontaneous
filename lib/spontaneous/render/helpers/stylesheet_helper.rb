# encoding: UTF-8

require 'sass'

module Spontaneous::Render::Helpers
  module StylesheetHelper
    extend self

    def stylesheets(*args)
      stylesheets = args.flatten
      return compressed_stylesheets(stylesheets) if live?
      stylesheets.map do |stylesheet|
        stylesheet_tag(stylesheet)
      end.join("\n")
    end

    alias_method :stylesheet, :stylesheets

    def stylesheet_tag(href)
      href = "#{href}.css" unless href =~ /\.css$/o
      %(<link rel="stylesheet" href="#{href}" />)
    end

    def compressed_stylesheets(stylesheets)
      file_paths = stylesheets.map { |style| [style, S::Render::Assets.find_file("#{style}.scss", "#{style}.css")] }
      invalid, file_paths = file_paths.partition { |url, path| path.nil? }
      roots = Spontaneous.instance.paths.expanded(:public)

      tags = []
      css = file_paths.map { |url, path|
        case path
        when /\.scss$/o
          load_paths = roots + [File.dirname(path), File.dirname(path) / "sass"]
          ::Sass::Engine.for_file(path, {
            :load_paths => load_paths,
            :cache => false,
            :style => :compressed
          }).render
        else
          File.read(path)
        end
      }.join
      compressed, hash = compress_css_string(css)
      output_path = Spontaneous::Render::Assets.path_for(revision, "#{hash}.css")
      FileUtils.mkdir_p(File.dirname(output_path))
      File.open(output_path, "w") { |file| file.write(compressed) }
      tags = [stylesheet_tag(Spontaneous::Render::Assets.url(hash))]
      tags.join("\n")
    end

    def compress_css_string(css_string)
      Spontaneous::Render::Assets::Compression.shine_compress_string(css_string, :css)
    end

  end
end
