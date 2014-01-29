module Spontaneous::Storage
  module Template
    autoload :Backend,     'spontaneous/storage/template/backend'
    autoload :File,        'spontaneous/storage/template/file'
    autoload :Moneta,      'spontaneous/storage/template/moneta'
    autoload :Proxy,       'spontaneous/storage/template/proxy'
    autoload :Revision,    'spontaneous/storage/template/revision'
    autoload :Store,       'spontaneous/storage/template/store'
    autoload :Transaction, 'spontaneous/storage/template/transaction'

    # Initializes a new store with the provided options
    # Uses moneta as a unified interface to  except in the special case of the :File
    # store which needs to work in a way compatible with the use of
    # an frontend HTTP proxy, e.g. Nginx
    def self.new(backend_class, options = {})
      backend = case backend_class
      when :File
        File.new(options[:root])
      else
        Moneta.new(backend_class, options)
      end
      Store.new(backend)
    end
  end
end
