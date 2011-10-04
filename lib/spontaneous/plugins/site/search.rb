# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Search
      module ClassMethods
        def index(name, &definition)
          instance.index(name, &definition)
        end

        def indexes
          instance.indexes
        end
      end

      module InstanceMethods
        def indexes
          @indexes ||= {}
        end

        def [](name)
          indexes[name.to_sym]
        end

        def []=(name, index)
          indexes[name.to_sym] = index
        end

        def index(name, &definition)
          index = S::Search::Index.new(name, &definition)
          self[name] = index
        end
      end
    end
  end
end

