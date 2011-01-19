
module Spontaneous::Render
  module Format; end

  class FormatBase
    def self.format
      @format ||= self.name.demodulize.downcase.to_sym
    end

    attr_reader :progress

    def initialize(revision, pages, progress=nil)
      @revision, @pages, @progress = revision, pages.find_all { |page| page.formats.include?(format) }, progress
    end

    def format
      self.class.format
    end

    def render
      before_render
      @pages.each_with_index do |page, n|
        render_page(page) if page.formats.include?(format)
        progress.page_rendered(n)
      end
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
      ext = ".#{format}"
      ext += ".#{render_engine.extension}" if render_engine.is_dynamic?(output)

      dir = revision_root / format / page.path
      path = dir / "/index#{ext}"
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end

    def revision_root
      S::Site.revision_dir(@revision)
    end

    def render_engine
      Spontaneous::Render.engine
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'format', '*.rb')].each do |format|
  require format
end
