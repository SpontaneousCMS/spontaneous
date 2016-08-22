
module Spontaneous
  module Output
    def self.create(output_name, options = {})
      options[:format] ||= generate_format(output_name)
      (output_class(output_name, options)).tap do |klass|
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
      Class.new(output_class)
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

    # Used in the console or any other place where we want to render
    # content outside of the Rack applications or publishing
    # system
    def self.default_renderer(format, site = Spontaneous::Site.instance)
      format_class_map[format.to_sym].default_renderer(site)
    end

    def self.published_renderer(format, site, revision)
      format_class_map[format.to_sym].published_renderer(site, revision)
    end

    def self.preview_renderer(format, site)
      format_class_map[format.to_sym].preview_renderer(site)
    end

    def self.asset_url(file = nil)
      File.join ["/rev", file].compact
    end

    def self.asset_path(revision = nil)
      Spontaneous.revision_dir(revision) / asset_url
    end

    autoload :Template,   "spontaneous/output/template"
    autoload :Context,    "spontaneous/output/context"
    autoload :Helpers,    "spontaneous/output/helpers"
    autoload :Renderable, "spontaneous/output/renderable"
    autoload :Store,      "spontaneous/output/store"
  end
end

# Loads in the default HTML & Plain formats
require 'spontaneous/output/format'
