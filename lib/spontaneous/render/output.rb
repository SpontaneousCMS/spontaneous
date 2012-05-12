
module Spontaneous::Render
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
      ext = ".#{format}"
      return format.to_sym if Rack::Mime::MIME_TYPES.key?(ext)
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

    class Format
      module ClassMethods
        def inherited(subclass)
          subclass.helper_formats.concat helper_formats
        end

        def provides_format(*formats)
          helper_formats.concat formats
          Output.register_format(self, *formats)
        end

        def helper_formats
          @helper_formats ||= []
        end

        def configure(output_name, options)
          format    = options[:format]
          extension = options[:extension]
          language  = options[:language]
          mimetype  = options[:mimetype] || options[:mime_type] || calculate_mimetype(format)
          options.update({
            :format => format.to_sym,
            :mimetype => mimetype,
            :extension => extension,
            :language => language
          })
          @name    = output_name.to_sym
          @options = default_options.merge(options)
        end

        def calculate_mimetype(format)
          ::Rack::Mime.mime_type(".#{format}", nil) || inherited_mimetype
        end

        def default_options
          { :private => false,
            :dynamic => false }
        end

        def inherited_mimetype
          ::Rack::Mime.mime_type(".#{helper_formats.first}")
        end

        def mimetype
          return inherited_mimetype if @options.nil?
          @options[:mimetype]
        end

        alias_method :mime_type, :mimetype
        def format
          @options[:format]
        end

        def name
          @name
        end

        alias_method :extension, :name

        def to_sym
          @name
        end

        def extension(is_dynamic = false, dynamic_extension = Spontaneous::Render.extension)
          if (override = @options[:extension])
            return normalise_extension(override.to_s)
          end
          ext =  normalise_extension(name.to_s)
          ext << ".#{self.dynamic_extension(dynamic_extension)}" if (is_dynamic or self.dynamic?)
          ext
        end

        def normalise_extension(ext)
          ext =  "." << ext unless ext.start_with?(".")
          ext
        end

        def dynamic_extension(default_extension)
          @options[:language] || default_extension
        end

        def private?
          @options[:private]
        end

        def public?
          !self.private?
        end

        def dynamic?
          @options[:dynamic]
        end

        def postprocess
          @options[:postprocess]
        end

        def context
          formats = (helper_formats + [name]).uniq.compact
          Spontaneous::Site.context formats
        end
      end

      extend ClassMethods
      extend Forwardable

      attr_reader :page

      def_delegators "self.class", :format, :dynamic?, :extension, :to_sym, :mimetype, :mime_type, :public?, :private?, :context, :name, :extension

      def initialize(page)
        @page = page
      end


      def render(params = {}, *args)
        before_render
        output = render_page(params, *args)
        output = postprocess(output)
        after_render(output)
        output
      end

      def before_render
      end

      def after_render(output)
      end

      def postprocess(output)
        if (process = self.class.postprocess) && (process.is_a?(Proc))
          output = process.call(@page, output)
        end
        output
      end

      def render_page(params = {}, *args)
        output = Spontaneous::Render.render(@page, self, params, *args)
        output
      end

      def publish_page(revision)
        rendered = render({:revision => revision})
        path = output_path(revision, rendered)
        File.open(path, 'w') do |file|
          case rendered
          when IO
            IO.copy_stream(rendered, file)
          else
            file.write(rendered.to_s)
          end
        end
      end

      def output_path(revision, output)
        ext = nil
        template_dynamic = Spontaneous.template_engine.is_dynamic?(output)
        path = Spontaneous::Render.output_path(revision, self, template_dynamic)

        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        path
      end
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'output', '*.rb')].each do |format|
  require format
end
