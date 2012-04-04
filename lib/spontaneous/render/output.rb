
module Spontaneous::Render
  class Output
    def self.renderer_class(format)
      format_class = nil
      begin
        format_class = self.const_get("#{format.to_s.camelize}")
      rescue NameError => e
        # Assume that the missing format is compatilble with the standard HTML
        # format in that each page generates a separate, self contained, file
        # .. probably true in most cases
        format_class = Class.new(Spontaneous::Render::FormatBase)
        self.const_set(format.to_s.camelize, format_class)
      end
      format_class
    end

    def self.formats
      self.constants.map { |const| const.to_s.downcase.to_sym }
    end

    attr_reader :format, :mime_type

    def initialize(format, options = {})
      mime_type = nil
      case format
      when String, Symbol
        @format = format.to_sym
        @mime_type = ::Rack::Mime.mime_type(".#{format}", nil)
      when Hash
        @format = format.keys.first.to_sym
        @mime_type = format.values.first
        @dynamic = format[:dynamic]
        @extension = format[:extension]
      end
      @dynamic ||= options[:dynamic] || false
      @extension ||= options[:extension]
    end

    def render(revision, page)
      renderer(revision, page).render
    end

    def renderer(revision, page)
      renderer_class.new(revision, page, self)
    end

    def renderer_class
      self.class.renderer_class(self)
    end

    def ==(other)
      (other.to_sym == self.to_sym) or (other.respond_to?(:format) and (other.format == self.format))
    end

    def eql?(other)
      other.is_a?(Output) and (self == other)
    end

    def hash
      format.to_s.hash
    end

    def to_sym
      format
    end

    def to_s
      format.to_s
    end

    def extension(is_dynamic = false, dynamic_extension = Spontaneous::Render.extension)
      ext = ".#{format}"
      ext << ".#{self.dynamic_extension(dynamic_extension)}" if (is_dynamic or self.dynamic?)
      ext
    end

    def dynamic_extension(default_extension)
      return @extension if @extension
      default_extension
    end

    def dynamic?
      @dynamic
    end

    def inspect
      %(<Output #{@format}>)
    end
  end

  class FormatBase

    def self.format
      @format ||= self.name.demodulize.downcase.to_sym
    end

    attr_reader :format

    def initialize(revision, page, format)
      @revision, @page, @format = revision, page, format
    end

    def render
      before_render
      render_page(@page)
      after_render
    end

    def before_render; end
    def after_render; end

    def render_page(page)
      output = page.render(format, {:revision => @revision})
      path = output_path(page, output)
      File.open(path, 'w') do |f|
        f.write(output)
      end
    end

    def output_path(page, output)
      ext = nil
      template_dynamic = Spontaneous.template_engine.is_dynamic?(output)
      path = Spontaneous::Render.output_path(@revision, page, format, renderer.extension, template_dynamic)

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end

    def revision_root
      Spontaneous.revision_dir(@revision)
    end

    def renderer
      Spontaneous::Render.renderer
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'output', '*.rb')].each do |format|
  require format
end
