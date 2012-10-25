# encoding: UTF-8

require 'simultaneous'

module Spontaneous
  module Publishing
    class Simultaneous

      def self.task_name
        # TODO: add site name to this to make it unique on a server
        :publish
      end

      def self.spot_binary
        ::Spontaneous.config.spontaneous_binary || default_spot_binary
      end

      def self.default_spot_binary
        (Pathname.new(Spontaneous.gem_dir) + "bin/spot").expand_path.to_s
      end

      def self.register_task
        publish_binary = spot_binary + " site publish"
        site_root = Pathname.new(Spontaneous.root).expand_path.to_s
        niceness = S.config.publish_niceness || 15
        logfile =  "#{site_root}/log/publish.log"
        # TODO: make nice value configurable
        task_options = {
          :niceness => niceness,
          :logfile => logfile,
          :pwd => site_root
        }

        task_params = {
          "site" => site_root,
          "logfile" => logfile,
          "environment" => Spontaneous.env
        }
        env = {
          "SPOT_SERVER" => server_address
        }
        ::Simultaneous.add_task(task_name, publish_binary, task_options, task_params, env)
      end

      def self.simultaneous_setup
        ::Simultaneous.client_mode  = :async
        ::Simultaneous.connection   = ::Spontaneous.config.simultaneous_connection
        ::Simultaneous.domain       = ::Spontaneous.config.site_domain
      end

      def self.server_address
        Spontaneous.config.server_connection || "#{ ::Spontaneous.config.host || "127.0.0.1" }:#{::Spontaneous.config.port}"
      end

      simultaneous_setup
      register_task

      # def self.status
      #   FAF.get_status(task_name)
      # end

      # def self.status=(status)
      #   FAF.set_status(task_name, status)
      # end

      attr_reader :revision

      def initialize(revision)
        @revision = revision
      end

      def task_name
        self.class.task_name
      end

      def publish_pages(page_list)
        ::Simultaneous.fire(task_name, {"pages" => page_list})
      end

      def publish_all
        ::Simultaneous.fire(task_name)
      end
    end # Simultaneous
  end # Publishing
end # Spontaneous


