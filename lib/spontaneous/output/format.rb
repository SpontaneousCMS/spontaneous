
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

      def calculated_mimetype
        calculate_mimetype(format)
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

      def custom_mimetype?
        calculated_mimetype != mimetype
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

      def to_s
        to_sym.to_s
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

      def options
        @options
      end

      def context(site = Spontaneous.instance)
        site.context (helper_formats + [name]).uniq.compact
      end
    end

    extend ClassMethods
    extend Forwardable

    attr_reader :page
    attr_accessor :content

    def_delegators "self.class", :format, :dynamic?, :extension, :to_sym,
      :mimetype, :mime_type, :custom_mimetype?,
      :public?, :private?, :context, :name, :extension, :options

    def initialize(page, content = nil)
      @page, @content = page, content
      @content ||= page
    end

    def model
      content.model
    end

    # Hook into Pages' ability to re-define the object that they render as
    def renderable_content
      content.renderable
    end

    def render(params = {}, parent_context = nil)
      render_using(default_renderer, params, parent_context)
    end

    def render_using(renderer, params = {}, parent_context = nil)
      before_render
      output = render_content(renderer, params, parent_context)
      output = postprocess(output)
      after_render(output)
      output
    end

    def default_renderer
      Spontaneous::Output.default_renderer
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

    def render_content(renderer, params = {}, parent_context = nil)
      renderer.render(self, params, parent_context)
    end

    def publish_page(renderer, revision, transaction)
      rendered = render_using(renderer, {:revision => revision})
      transaction.store_output(self, renderer.is_dynamic_template?(rendered), rendered)
    end

    def output_path(revision, render)
      template_dynamic = Spontaneous::Output::Template.is_dynamic?(render)
      path = Spontaneous::Output.output_path(revision, self, template_dynamic)

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.class == self.class && other.page == self.page
    end

    def hash
      [self.class, page, options].hash
    end

    def url_path
      path = page.path
      path = "/index" if path == "/"
      [path, name].join(".")
    end

    def output_protected?
      private? || custom_mimetype?
    end

    def protected?
      output_protected? || page.dynamic? || page.in_private_tree?
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'format', '*.rb')].each do |format|
  require format
end
