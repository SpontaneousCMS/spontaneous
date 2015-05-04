module Spontaneous::Publishing
  class Transaction

    attr_reader :site, :revision, :pages, :progress

    def initialize(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new)
      @site, @revision, @pages, @progress = site, revision, pages, progress
    end

    def rollback
      render_transaction.rollback if @render_transaction
    end

    def commit
      render_transaction.commit
      @render_transaction = nil
    end

    def render_transaction
      @render_transaction ||= template_revision.transaction
    end

    def render_transaction?
      !@render_transaction.nil?
    end

    def template_revision
      @template_revision ||= @site.output_store.revision(@revision)
    end
  end
end
