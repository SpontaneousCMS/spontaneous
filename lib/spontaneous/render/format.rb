
module Spontaneous::Render
  module Format
    def self.for(format)
      self.const_get("#{format.to_s.camelize}")
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
      ext = renderer.extension if Spontaneous.template_engine.is_dynamic?(output)
      path = Spontaneous::Render.output_path(@revision, page, format, ext)

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
