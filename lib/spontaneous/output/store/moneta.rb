require 'moneta'
require 'json'

module Spontaneous::Output::Store
  # Implements the template store API on top of a Moneta key-value store.
  #
  # Unlike the File backend, we don't need to differentiate the storage
  # locations of static, protected & dynamic templates because no integration
  # with Nginx (etc) is possible
  #
  # This is not thread safe because the operations at the revision level aren't
  # thread safe, although the simple load/store template operations are. In the
  # current use case this isn't a problem & isn't likely to be one - template
  # generation is a part of publishing & the logical way to speed up publishing
  # is to split the rendering of pages across multiple processes in a map-reduce
  # pattern which would leave the Transaction#commit & Transaction#rollback
  # operations, which use the revision level methods, as the `reduce` phase
  # which is single threaded whilst the template inserts would need to support
  # concurrent access.
  class Moneta < Backend
    REVISION_SEP = ":".freeze

    attr_reader :backend

    def initialize(name, options = {})
      @backend = ::Moneta.build do
        adapter name, options
      end
    end

    def add_revision(revision, keys)
      save_revisions(revisions.push(revision))
      @backend.store(revision_key(revision), serialize(keys))
    end

    def revisions
      unserialize(@backend.load(revisions_key)) || []
    end

    def delete_revision(revision, keys = nil)
      revision_list = revisions
      if revision_list.delete(revision)
        keys ||= unserialize @backend.load(revision_key(revision))
        save_revisions(revision_list)
      end
      @backend.delete(revision_key(revision))
      # want to delete the keys even if the revision hasn't been created
      # this covers the case of a transaction rollback where
      # we have a list of keys but no committed revision
      keys.each do |key|
        @backend.delete(key)
      end if keys
    end

    def revision_key(revision)
      ":revision:#{revision}"
    end

    def revisions_key
      ":revisions:"
    end

    protected

    # The Template class wraps a String template response with IO characteristics
    # based on StringIO & also supplies File-like characteristics by
    # providing a #path method.
    #
    # The IO methods provide an #each method for Rack, and
    # the #path method can be used by the rendering engine for caching.
    #
    # We don't provide a #to_path method for Rack because there
    # is no file represantation of this object for passing to a proxy
    # server
    class Template < StringIO
      def initialize(template, path)
        @path = path
        super(template)
      end

      attr_reader :path
    end

    def store(revision, partition, path, template, transaction)
      key = key_for(revision, partition, path)
      transaction.push(key) if transaction
      @backend.store(key, template)
    end

    def load(revision, partition, path)
      if (template = @backend.load(key_for(revision, partition, path)))
        return Template.new(template, path_for(revision, partition, path))
      end
      nil
    end

    def key_for(revision, partition, path)
      [revision, partition, path].join(REVISION_SEP)
    end

    def path_for(revision, partition, path)
      ::File.join(Spontaneous::SLASH, revision.to_s, partition, path)
    end

    def serialize(obj)
      Spontaneous::JSON.encode(obj)
    end

    def unserialize(obj)
      Spontaneous::JSON.parse(obj)
    end

    def save_revisions(revisions)
      @backend.store(revisions_key, serialize(revisions.sort))
    end
  end
end
