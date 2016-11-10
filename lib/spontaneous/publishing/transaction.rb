module Spontaneous::Publishing
  class Transaction

    attr_reader :site, :revision, :pages, :progress, :user

    def initialize(site, revision, pages, progress = Spontaneous::Publishing::Progress::Silent.new, user = nil)
      @site, @revision, @pages, @progress, @user = site, revision, pages, progress, user
    end

    def rollback
      render_transaction.rollback if @render_transaction
    end

    def commit
      render_transaction.commit
      @render_transaction = nil
    end

    def store_output(output, dynamic, template)
      render_transaction.store_output(output, dynamic, template)
    end

    def store_asset(key, asset)
      render_transaction.store_asset(key, asset)
    end

    def store_static(key, file)
      render_transaction.store_static(key, file)
    end

    # stores call this method to register the keys
    # they write to their backends. this is necessary
    # because we don't want to limit our backends to those
    # that are able to return keys based on a glob
    def push(key)
      @index.push(key)
    end

    def asset_manifests
      site.asset_manifests
    end

    # Called at the start of the publishing process to allow output stores to
    # sanity check their config and connections. Will raise an exception if the
    # output store's validation fails.
    def validate_output_store
      render_transaction
    end

    def publishing?
      true
    end

    def development?
      Spontaneous.development?
    end

    protected

    def render_transaction
      @render_transaction ||= template_revision.transaction
    end

    def template_revision
      @template_revision ||= @site.output_store.revision(@revision)
    end
  end
end
