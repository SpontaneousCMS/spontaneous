# encoding: UTF-8

module Spontaneous::Cli
  class Init
    class MySQL < Db

      def create_database_commands(opts)
        host = opts[:host].blank? ? "" : "@#{opts[:host]}"
        cmds = [ ["CREATE DATABASE `#{opts[:database]}` CHARACTER SET UTF8", true] ]
        unless opts[:user] == "root"
          cmds << ["GRANT ALL ON `#{opts[:database]}`.* TO `#{opts[:user]}`#{host} IDENTIFIED BY '#{opts[:password]}'", false]
        end
        cmds
      end
    end
  end
end
