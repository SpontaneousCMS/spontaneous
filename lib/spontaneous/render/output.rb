
module Spontaneous::Render
  module Output
    def self.create(output_name, options = {})
      format  = options[:format]
      if format.nil?
        format = output_name
        format = :html if unknown_format?(format)
      end
      options[:format] = format.to_sym
      c = (output_class(format)).tap do |klass|
        klass.configure(output_name, options)
      end
    end

    def self.output_class(format)
      baseclass = Spontaneous::Render::Output::Format
      output_class = format_class_map[format] || create_output_class(baseclass, format)
      Class.new(output_class)
      end

      def self.create_output_class(baseclass, format)
        output_class = Class.new(baseclass)
        self.register_format(output_class, format)
        self.const_set(format.to_s.upcase, output_class)
        output_class
      end

      def self.unknown_format?(format)
        ::Rack::Mime.mime_type(".#{format}", nil).nil?
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
          def register_format(klass, *formats)
            Output.register_format(klass, *formats)
          end

          def configure(output_name, options)
            format    = options[:format]
            extension = options[:extension]
            language  = options[:language]
            mimetype  = options[:mimetype] || options[:mime_type] || ::Rack::Mime.mime_type(".#{format}")
            options.update({
              :format => format.to_sym,
              :mimetype => mimetype,
              :extension => extension,
              :language => language
            })
            @name    = output_name.to_sym
            @options = default_options.merge(options)
          end

          def default_options
            { :private => false,
              :dynamic => false }
          end

          def format
            @options[:format]
          end

          def name
            @name
          end

          def to_sym
            @name
          end

          def mimetype
            @options[:mimetype]
          end

          alias_method :mime_type, :mimetype

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
        end

        extend ClassMethods
        extend Forwardable

        attr_reader :page

        def_delegators "self.class", :format, :dynamic?, :extension, :to_sym, :mimetype, :mime_type, :public?, :private?

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
          output = Spontaneous::Render.render(@page, self.format, params, *args)
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
          path = Spontaneous::Render.output_path(revision, @page, format, extension, template_dynamic)

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
