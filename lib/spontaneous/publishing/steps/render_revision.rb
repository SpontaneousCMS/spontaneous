module Spontaneous::Publishing::Steps
  class RenderRevision < BaseStep

    # Wrap any exceptions raised during the render with information
    # about the page+output that raised the error (preserving the
    # stack trace)
    class RenderException < Spontaneous::Error
      def initialize(output, exception)
        super("Exception rendering page #{output.url_path.inspect}: #{exception}")
        set_backtrace(exception.backtrace)
      end
    end

    def call
      progress.stage('rendering')
      render_pages
    end

    def count
      renderable_pages.map { |page| page.outputs.length }.inject(0, :+)
    end

    def rollback
    end

    def render_pages
      renderable_pages.each do |page|
        render_page(page)
      end
    end

    def render_page(page)
      page.outputs.each do |output|
        render_output(output)
      end
    end

    def render_output(output)
      output.publish_page(renderer, revision, transaction)
      progress.step(1, output.url_path.inspect)
    rescue => e
      raise RenderException.new(output, e)
    end

    def renderer
      @renderer ||= Spontaneous::Output::Template::PublishRenderer.new(transaction, true)
    end

    def renderable_pages
      site.pages
    end
  end
end
