# encoding: UTF-8

class Spontaneous::Site
  module Publishing
    extend Spontaneous::Concern

    def background_mode
      @background_mode ||= (config.background_mode || :immediate)
    end

    def background_mode=(method)
      @background_mode = method
    end

    def resolve_background_mode(mod)
      klass_name = background_mode.to_s.camelize
      begin
        mod.const_get(klass_name)
      rescue NameError => e
        puts "Unknown method #{method} (#{mod}::#{klass_name})"
        mod::Immediate
      rescue NameError => e
        raise "Illegal background mode #{mod}::Immediate"
      end
    end

    def publish(&block)
      self.publish_steps = Spontaneous::Publishing::Steps.new(&block)
    end

    def publish_steps=(steps)
      @publish_steps = steps
    end

    def publish_steps
      @publish_steps || minimal_publish_steps
    end

    # Provides a fallback publishing pipeline in case none has been defined
    # used really only in tests
    def minimal_publish_steps
      Spontaneous::Publishing::Steps.minimal
    end

    def rerender_steps
      Spontaneous::Publishing::Steps.rerender(publish_steps)
    end

    def reindex_steps
      Spontaneous::Publishing::Steps.reindex(publish_steps)
    end

    def publishing_method
      resolve_background_mode(Spontaneous::Publishing)
    end

    def output_store(*args)
      return current_output_store if args.empty?
      @output_store = Spontaneous::Output::Store.new(*args)
    end

    def current_output_store
      @output_store ||= Spontaneous::Output::Store.new(:File, root: revision_root)
    end

    def publish_pages(page_list=nil, user = nil)
      publishing_method.new(self, working_revision, publish_steps).publish_pages(page_list, user)
    end

    def publish_all(user = nil)
      publishing_method.new(self, working_revision, publish_steps).publish_all(user)
    end

    def rerender
      publishing_method.new(self, published_revision, rerender_steps).rerender
    end

    def reindex
      publishing_method.new(self, published_revision, reindex_steps).reindex
    end

    def publishing_status
      status = rest = nil
      # if r = S::Site.pending_revision
      status, *rest = publishing_method.status.split(':')
      rest = rest.join(':')
      # end
      Hash[[:status, :progress].zip([status, rest])] rescue ""
    end

    def publishing_status=(status)
      publishing_method.status = status
    end

    def with_published(&block)
      model.scope(published_revision, true, &block)
    end

    def with_editable(&block)
      model.scope(nil, false, &block)
    end

    def with_preview(&block)
      model.scope(nil, true, &block)
    end

    protected

    def set_published_revision(revision)
      instance = S::State.instance
      instance.published_revision = revision
      instance.revision = revision + 1
      instance.save
    end

    def pending_revision=(revision)
      instance = S::State.instance
      instance.pending_revision = revision
      instance.save
    end
  end # Publishing
end # Spontaneous::Plugins::Site
