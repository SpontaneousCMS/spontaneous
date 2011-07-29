# encoding: UTF-8

module Spontaneous
  module Cli
    module Adapter
      class << self
        def start(options)
          ::Spontaneous::Server.run!(options)
        end
      end
    end # Adapter
  end # Cli
end # Spontaneous
