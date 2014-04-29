module Spontaneous::Publishing::Steps
  class CopyStaticFiles < BaseStep

    def count
      facets.length
    end

    def call
      @progress.stage("copying files")
      facets.each do |facet|
        copy_facet(facet)
        @progress.step(1)
      end
    end

    def rollback
      FileUtils.rm_r(revision_public) if File.exists?(revision_public)
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

    def copy_file(facet, source, path)
      dest = File.join([revision_public, facet.file_namespace, path].compact)
      dir = File.dirname(dest)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      link_file(source, dest)
    end

    def link_file(source, dest)
      src_dev = File::stat(source).dev
      dst_dev = File::stat(File.dirname(dest)).dev
      if (src_dev == dst_dev)
        FileUtils.ln(source, dest, :force => true)
      else
        FileUtils.cp(source, dest)
      end
    end

    def files(dir)
      Dir["#{dir}/**/*"]
      .reject {|path| ::File.directory?(path) }
      .map { |path| [path, Pathname.new(path).relative_path_from(dir).to_s] }
    end

    def revision_public
      @public_dest ||= Pathname.new(Spontaneous.revision_dir(revision) / 'public').tap do |path|
        FileUtils.mkdir_p(path) unless File.exists?(path)
      end
    end

    def facets
      @site.facets
    end

    def sources(facet)
      facet.paths.expanded(:public).map { |dir| Pathname.new(dir) }.select(&:exist?).map(&:realpath)
    end
  end
end
