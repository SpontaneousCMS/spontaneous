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
      @progress.stage("rendering")
      render_pages
      commit
    end

    def count
      @site.pages.map { |page| page.outputs.length }.inject(0, :+)
    end

    def rollback
      render_transaction.rollback if @render_transaction
      template_revision.delete
    end

    def render_pages
      @site.pages.each do |page|
        render_page(page)
      end
    end

    def commit
      render_transaction.commit
      @render_transaction = nil
    end

    def render_page(page)
      page.outputs.each do |output|
        render_output(output)
      end
    end

    def render_output(output)
      output.publish_page(renderer, revision, render_transaction)
      @progress.step(1, output.url_path.inspect)
    rescue => e
      raise RenderException.new(output, e)
    end

    def renderer
      @renderer ||= Spontaneous::Output::Template::PublishRenderer.new(@site, true)
    end

    def render_transaction
      @render_transaction ||= template_revision.transaction
    end

    def template_revision
      @template_revision ||= @site.output_store.revision(@revision)
    end
  end
end
