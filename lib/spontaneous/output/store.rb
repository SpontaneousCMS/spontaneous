module Spontaneous::Output
  module Store
    autoload :Backend,     'spontaneous/output/store/backend'
    autoload :File,        'spontaneous/output/store/file'
    autoload :Moneta,      'spontaneous/output/store/moneta'
    autoload :Revision,    'spontaneous/output/store/revision'
    autoload :Store,       'spontaneous/output/store/store'
    autoload :Transaction, 'spontaneous/output/store/transaction'

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
