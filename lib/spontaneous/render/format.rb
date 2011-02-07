
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
        after_page_rendered(page)
      end
      after_render
    end

    def after_page_rendered(page)
      progress.page_rendered(page) if progress
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
      ext = renderer.extension if renderer.is_dynamic?(output)
      path = Spontaneous::Render.output_path(@revision, page, format, ext)

      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      path
    end

    def revision_root
      S::Site.revision_dir(@revision)
    end

    def renderer
      Spontaneous::Render.renderer
    end
  end
end

Dir[File.join(File.dirname(__FILE__), 'format', '*.rb')].each do |format|
  require format
end
