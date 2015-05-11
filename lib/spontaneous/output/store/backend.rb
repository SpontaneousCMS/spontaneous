module Spontaneous::Output::Store
  class Backend
    def initialize(options = {})
    end

    def store_static(revision, key, template, transaction = nil)
      store(revision, :static, key, template, transaction)
    end

    def store_protected(revision, key, template, transaction = nil)
      store(revision, :protected, key, template, transaction)
    end

    def store_dynamic(revision, key, template, transaction = nil)
      store(revision, :dynamic, key, template, transaction)
    end

    def store_asset(revision, key, template, transaction = nil)
      store(revision, :assets, key, template, transaction)
    end

    def load_static(revision, key)
      load(revision, :static, key, static: true)
    end

    def load_protected(revision, key)
      load(revision, :protected, key, static: false)
    end

    def load_dynamic(revision, key)
      load(revision, :dynamic, key, static: false)
    end

    def load_asset(revision, key)
      load(revision, :assets, key, static: true)
    end

    # Called by transactions when they are created, should be used by the
    # backend implementations to test their configuration and the connectivity
    # of their backing stores. This method should raise an error in the case of
    # any problem.
    def start_revision(revision)
    end

    # Retrieves the number of the current active revision
    def current_revision
      raise NotImplementedError
    end

    # Creates the given revision in the store with the given keys
    def add_revision(revision, keys)
      raise NotImplementedError
    end

    # Makes the given revision the current revision
    def activate_revision(revision)
      raise NotImplementedError
    end

    # Removes a revision from the store
    def delete_revision(revision)
      raise NotImplementedError
    end

    # Lists all known revisions currently held in the store
    def revisions
      raise NotImplementedError
    end

    # Retrieves the keys associated with the given revision
    def revision(revision)
      raise NotImplementedError
    end

    # Maps a given output to the right path within the store.  Files in the
    # store are always held with an extension because in most stores we have no
    # way of associating content type metadata to the files
    def output_key(output, dynamic = false)
      path = output.page.path
      ext  = output.extension(dynamic)
      case path
      when Spontaneous::SLASH
        "/index#{ext}"
      else
        "#{path}#{ext}"
      end
    end

    protected

    # The low-level implementation of the store action, backend specific
    def store(revision, partition, path, template, transaction)
      raise NotImplementedError
    end

    def load(revision, partition, path)
      raise NotImplementedError
    end
  end
end
