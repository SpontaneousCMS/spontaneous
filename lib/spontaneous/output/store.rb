module Spontaneous::Output
  module Store
    autoload :Backend,     'spontaneous/output/store/backend'
    autoload :File,        'spontaneous/output/store/file'
    autoload :Fog,         'spontaneous/output/store/fog'
    autoload :Moneta,      'spontaneous/output/store/moneta'
    autoload :Revision,    'spontaneous/output/store/revision'
    autoload :Store,       'spontaneous/output/store/store'
    autoload :Transaction, 'spontaneous/output/store/transaction'

    # Initializes a new store with the provided options. Uses Moneta as a
    # unified interface to key value stores but also provides specialized
    # backing store implementations suitable for use behind a standard
    # file-based HTTP server (such as Nginx or Apache) or cloud storage.
    def self.new(adapter, options = {})
      backend = backing_class(adapter).new(options.merge(adapter: adapter))
      Store.new(backend)
    end

    def self.backing_class(adapter)
      return Moneta unless const_defined?(adapter)
      const_get(adapter)
    end
  end
end
