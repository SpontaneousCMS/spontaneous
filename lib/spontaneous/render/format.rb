
module Spontaneous::Render
  module Format
    def self.for(format)
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
  end

  class FormatBase
    def self.format
      @format ||= self.name.demodulize.downcase.to_sym
    end

    def initialize(revision, page)
      @revision, @page = revision, page
    end

    def format
      self.class.format
    end

    def render
      before_render
      render_page(@page)
      after_render
    end

    def before_render; end
    def after_render; end

    def render_page(page)
      output = page.render(format)
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

Dir[File.join(File.dirname(__FILE__), 'format', '*.rb')].each do |format|
  require format
end
