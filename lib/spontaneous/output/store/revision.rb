module Spontaneous::Output::Store
  class Revision
    attr_reader :revision, :store


    def initialize(revision, store)
      @revision, @store = revision, store
    end

    def transaction
      @transaction ||= transaction!
    end

    def transaction!
      Transaction.new(@revision, @store)
    end

    # Tests for the existance of a static template
    # This provides a way to short-cut the render step as
    # if this returns a non-nil result then we can reply
    # directly to the request with this template & skip the
    # render step
    def static_template(output)
      key = @store.output_key(output)
      @store.load_static(@revision, key)
    end

    def protected_template(output)
      key = @store.output_key(output)
      @store.load_protected(@revision, key)
    end

    # Return a template for the given output
    def dynamic_template(output, request = nil)
      key = @store.output_key(output, true)
      @store.load_dynamic(@revision, key)
    end

    def static_asset(key)
      @store.load_asset(@revision, key)
    end

    def static_file(key)
      @store.load_static(@revision, key)
    end

    def load(namespace, key, static:)
      @store.load(@revision, namespace, key, static: static)
    end

    def activate
      @store.activate_revision(@revision)
    end

    def delete
      @store.delete_revision(@revision)
    end
  end
end
