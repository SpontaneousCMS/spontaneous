
module Spontaneous
  module Output
    def self.create(output_name, options = {})
      options[:format] ||= generate_format(output_name)
      c = (output_class(output_name, options)).tap do |klass|
        klass.configure(output_name, options)
      end
    end

    def self.generate_format(output_name)
      if format_class_map.key?(output_name) or real_format?(output_name)
        output_name
      else
        :html
      end
    end

    def self.output_class(output_name, options)
      format = options[:format]
      unless (output_class = format_class_map[format])
        output_class = create_output_class(format_class_map[:plain], format)
        format_class_map[format] = output_class
      end
      c = Class.new(output_class)
    end

    def self.real_format?(format)
      return format.to_sym if ::Rack::Mime::MIME_TYPES.key?(".#{format}")
      nil
    end

    def self.create_output_class(baseclass, format)
      output_class = Class.new(baseclass) do
      end
      self.register_format(output_class, format)
      self.const_set(format.to_s.upcase, output_class)
      output_class
    end

    def self.unknown_format?(format)
      !format_class_map.key?(format.to_sym)
    end

    def self.format_class_map
      @format_class_map ||= {}
    end

    def self.register_format(klass, *formats)
      formats.each do |f|
        format_class_map[f] = klass
      end
    end

    def self.output_path(revision, output, template_dynamic = false, request_method = "GET")
      output_path_with_root(revision_root(revision), revision, output, template_dynamic, request_method)
    end

    def self.output_path_with_root(root, revision, output, template_dynamic = false, request_method = "GET")
      segment = case
                when template_dynamic || output.dynamic?
                  "dynamic"
                when output.page.dynamic?(request_method)
                  "protected"
                else
                  "static"
                end
      path = output.page.path
      dir  = root / segment / path
      ext  = output.extension(template_dynamic)

      file = "#{dir}#{ext}"
      file = dir / "/index#{ext}" if path == "/" # root is a special case, as always
      file
    end

    # TODO: Is this ever used? Delete it & see what breaks
    def self.revision_dir(revision=nil, root = nil)
      Spontaneous::Site.instance.revision_dir(revision, root)
    end

    def self.revision_root(revision)
      Spontaneous::Site.instance.revision_dir(revision)
    end

    def self.context_class
      Cutaneous::Context
    end

    def self.cache_templates?
      @cache_templates ||= Spontaneous.production?
    end

    def self.cache_templates=(value)
      @cache_templates = value
    end

    def self.write_compiled_scripts=(state)
      @write_compiled_scripts = !!state
    end

    def self.write_compiled_scripts?
      @write_compiled_scripts = Spontaneous.production? unless defined?(@write_compiled_scripts)
      @write_compiled_scripts
    end

    def self.template_engine_class(cache = cache_templates?)
      if cache
        cached_engine_class
      else
        uncached_engine_class
      end
    end

    def self.cached_engine_class
      Cutaneous::CachingEngine
    end

    def self.uncached_engine_class
      Cutaneous::Engine
    end

    def self.renderer
      @renderer ||= default_renderer
    end

    def self.renderer=(renderer)
      @renderer = renderer
    end

    def self.default_renderer
      Template::Renderer.new
    end

    def self.published_renderer(revision = Spontaneous::State.published_revision)
      Template::PublishedRenderer.new(revision)
    end

    def self.preview_renderer
      Template::PreviewRenderer.new
    end

    def self.template_exists?(root, template, format)
      renderer.template_exists?(root, template, format)
    end

    def self.asset_url(file = nil)
      File.join ["/rev", file].compact
    end

    def self.asset_path(revision = nil)
      Spontaneous.revision_dir(revision) / asset_url
    end

    autoload :Template, "spontaneous/output/template"
    autoload :Context,  "spontaneous/output/context"
    autoload :Helpers,  "spontaneous/output/helpers"
    autoload :Assets,   "spontaneous/output/assets"
  end
end

# Loads in the default HTML & Plain formats
require 'spontaneous/output/format'
