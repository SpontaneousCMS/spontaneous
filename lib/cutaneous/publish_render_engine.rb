# encoding: UTF-8

module Cutaneous
  class PublishRenderEngine < RenderEngine

    @@revision = nil

    def self.revision
      @@revision
    end

    def self.[](revision)
      @@revision = revision
      self
    end

    def self.render_root
      S::Site.revision_dir(@@revision)
    end

    def render_engine
      @render_engine ||= FirstRenderEngine.new(@template_root)
    end


    def is_dynamic?(render)
      Template::STMT_PATTERN === render || Template::EXPR_PATTERN === render
    end

    def render_content(page, format=:html, params={})
      output = render_engine.render_content(page, format)
      ext = ".#{format}"
      ext += ".#{Cutaneous.extension}" if is_dynamic?(output)

      dir = self.class.render_root / page.path
      path = dir / "/index#{ext}"
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      File.open(path, 'w') do |f|
        f.write(output)
      end
      output
    end
  end
end

