# encoding: UTF-8

require 'fileutils'

module Spontaneous::Cli
  class Init
    class Sqlite < Db
      def create_database(connection)
        FileUtils.mkdir_p(File.join(@cli.options.site, 'db'))
      end
    end
  end
end
