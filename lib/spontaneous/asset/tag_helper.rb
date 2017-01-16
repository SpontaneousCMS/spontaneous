module Spontaneous::Asset
    class TagHelper
      attr_reader :site
      def initialize(site, manifests, ext)
        @site = site
        @manifests = manifests
        @ext = ext
      end

      def urls(*paths)
        paths = Array(paths).flatten
        _options = paths.extract_options!

        valid, invalid  = paths.each_with_index.
          map { |path, n| [path, n] }.
          partition { |path, n| @manifests.match?(ensure_ext(path)) }
        assets = valid.map { |path, n|
          [@manifests.lookup(ensure_ext(path)), n]
        }
        urls = Array.new(paths.length)
        (assets + invalid).each { |p, n| urls[n] = p }
        urls
      end

      def ensure_ext(path)
        return path if ::File.extname(path) == @ext
        "#{path}#{@ext}"
      end

      def tag(src)
        %(<script type="text/javascript" src="#{src}"></script>)
      end
    end
end
