# encoding: UTF-8

module Spontaneous
  module Application
    class Plugin < Spontaneous::Facet
      def init!
        init_file = @root / "init.rb"
        require(init_file) if File.exist?(init_file)
        super
      end
    end # Plugin
  end # Application
end # Spontaneous
