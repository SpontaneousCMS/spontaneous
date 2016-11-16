require 'json'
require 'digest/md5'

module Spontaneous::Asset
  class Compiler
    # Given a source dir containing a manifest file and a dest dir, this
    # compiles the given assets from the source to the dest directories. If a
    # file in the source dir corresponds to an entry in the manifest then the
    # file is copied as-is (under the assumption that any fingerprinting has
    # already been done). But if the source file isn't in the manifest then
    # it's copied to a fingerprinted path in the dest dir and an entry is added
    # to the manifest file in the destination dir.

    attr_reader :src_dir, :dst_dir

    def initialize(src_dir, dst_dir, manifest_filename = 'manifest.json')
      @src_dir, @dst_dir = ensure_directories(src_dir, dst_dir)
      @manifest_filename = manifest_filename
    end

    def run(fingerprinter = default_fingerprinter, progress = nil)
      @compiled_manifest ||= compile_manifest(fingerprinter || default_fingerprinter, progress)
    end

    def compile_manifest(fingerprinter, progress)
      write_manifest(copy_files(fingerprinter, progress))
    end

    def write_manifest(compiled_manifest)
      ::File.open(dst_path(@manifest_filename), 'w:UTF-8') { |f|
        f.write(compiled_manifest.to_json)
      }
      compiled_manifest
    end

    def default_fingerprinter
      proc { |basename, md5, ext| "#{basename}-#{md5}#{ext}" }
    end

    def copy_files(fingerprinter, progress)
      m = {}
      included = manifest.invert
      src_files.each do |src|
        if (logical = included[src])
          copy_without_fingerprint(src, progress)
          m[logical] = src
        else
          m[src] = copy_with_fingerprint(src, fingerprinter, progress)
        end
      end
      m
    end

    def src_files
      Dir["#{src_dir}/**/*.*"]
        .map { |path| strip_src(path) }
        .reject { |path| path == @manifest_filename}
    end

    def strip_src(path)
      path[(src_dir.length + 1)..-1]
    end

    def copy_with_fingerprint(file, fingerprinter, progress)
      src = src_path(file)
      md5 = Digest::MD5.file(src).hexdigest
      dir = ::File.dirname(file)
      dir = "" if dir == "."
      ext = ::File.extname(file)
      name = fingerprinter.call(::File.basename(file, ext), md5, ext)
      asset = ::File.join([dir, name].reject(&:empty?))
      progress.call(file, asset) unless progress.nil?
      dst = dst_path(asset)
      copy(src, dst)
      asset
    end

    def copy_without_fingerprint(file, progress)
      progress.call(file, file) unless progress.nil?
      src = src_path(file)
      dst = dst_path(file)
      copy(src, dst)
    end

    def copy(src, dst)
      dir = ::File.dirname(dst)
      ::FileUtils.mkdir_p(dir) unless ::File.directory?(dir)
      ::FileUtils.cp(src, dst)
    end

    def ensure_directories(*dirs)
      dirs.each do |dir|
        raise "Invalid directory #{dir}" unless ::File.directory?(dir)
      end
      dirs.map { |dir| ::File.expand_path(dir) }
    end

    def manifest
      @manifest ||= generate_manifest
    end

    def generate_manifest
      return {} unless has_manifest?
      parse_manifest(read_manifest)
    end

    def parse_manifest(manifest_json)
      begin
        JSON.parse(manifest_json)
      rescue => e
        $stderr.puts "Got error parsing manifest file #{manifest_path} #{e}"
        {}
      end
    end

    def read_manifest
      ::File.read(manifest_path)
    end

    def has_manifest?
      ::File.exist?(manifest_path)
    end

    def manifest_path
      src_path(@manifest_filename)
    end

    def src_path(path)
      ::File.join(src_dir, path)
    end

    def dst_path(path)
      ::File.join(dst_dir, path)
    end
  end
end
