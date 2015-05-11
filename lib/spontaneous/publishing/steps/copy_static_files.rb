module Spontaneous::Publishing::Steps
  class CopyStaticFiles < BaseStep

    def count
      facets.length
    end

    def call
      progress.stage("copying files")
      facets.each do |facet|
        copy_facet(facet)
        progress.step(1, "from #{facet.name.inspect}")
      end
    end

    def copy_facet(facet)
      sources(facet).each do |dir|
        copy_files(facet, dir)
      end
    end

    def copy_files(facet, dir)
      files(dir).each do |source, path|
        copy_file(facet, source, path)
      end
    end

    # TODO: Pass an IO object rather than do a File::read
    def copy_file(facet, source, path)
      key = File.join([facet.file_namespace, path].compact)
      transaction.store_static(make_absolute(key), ::File.binread(source))
    end

    def make_absolute(path)
      ::File.join('/', path)
    end

    def files(dir)
      Dir["#{dir}/**/*"]
      .reject {|path| ::File.directory?(path) }
      .map { |path| [path, Pathname.new(path).relative_path_from(dir).to_s] }
    end

    def facets
      site.facets
    end

    def sources(facet)
      facet.paths.expanded(:public).map { |dir| Pathname.new(dir) }.select(&:exist?).map(&:realpath)
    end
  end
end
