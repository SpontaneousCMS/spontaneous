
module Spontaneous::Output
  class Format
    module ClassMethods
      # class_attribute :template_engine

      def inherited(subclass)
        subclass.helper_formats.concat helper_formats
      end

      def provides_format(*formats)
        helper_formats.concat formats
        Spontaneous::Output.register_format(self, *formats)
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

      def extension(is_dynamic = false, dynamic_extension = Spontaneous::Output::Template.extension)
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
        Spontaneous::Site.context (helper_formats + [name]).uniq.compact
      end
    end

    extend ClassMethods
    extend Forwardable

    attr_reader :page
    attr_accessor :content

    def_delegators "self.class", :format, :dynamic?, :extension, :to_sym, :mimetype, :mime_type, :public?, :private?, :context, :name, :extension

    def initialize(page, content = nil)
      @page, @content = page, content
      @content ||= page
    end

    def model
      content.model
    end

    def render(params = {}, *args)
      render_using(default_renderer, params, *args)
    end

    def render_using(renderer, params, *args)
      before_render
      output = render_page(renderer, params, *args)
      output = postprocess(output)
      after_render(output)
      output
    end

    def default_renderer
      Spontaneous::Output.renderer
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

    def render_page(renderer, params = {}, *args)
      renderer.render(self, params, *args)
    end

    def publish_page(renderer, revision)
      rendered = render_using(renderer, {:revision => revision})
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

    def output_path(revision, render)
      ext = nil
      template_dynamic = Spontaneous::Output::Template.is_dynamic?(render)
      path = Spontaneous::Output.output_path(revision, self, template_dynamic)

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'format', '*.rb')].each do |format|
  require format
end
