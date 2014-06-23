# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class MySQL < Db

      def create_database_commands(config)
        host = config[:host].blank? ? "" : "@#{config[:host]}"
        cmds = [ ["CREATE DATABASE `#{config[:database]}` CHARACTER SET UTF8", true] ]
        unless config[:user] == "root"
          cmds << ["GRANT ALL ON `#{config[:database]}`.* TO `#{config[:user]}`#{host} IDENTIFIED BY '#{config[:password]}'", false]
        end
        cmds
      end
    end
  end
end
