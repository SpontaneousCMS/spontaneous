# encoding: UTF-8

module Spontaneous
  module Application
    class Plugin < Spontaneous::Facet
      def load!
        init_file = @root / "init.rb"
        if File.exist?(init_file)
          require(init_file)
        end
        super
      end
    end # Plugin
  end # Application
end # Spontaneous
