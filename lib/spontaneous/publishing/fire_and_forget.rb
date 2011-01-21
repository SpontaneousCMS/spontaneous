# encoding: UTF-8

require 'fire_and_forget'

module Spontaneous
  module Publishing
    class FireAndForget
      FAF = ::FireAndForget

      def self.task_name
        # TODO: add site name to this to make it unique on a server
        :publish
      end

      def self.register_task
        publish_binary = (Pathname.new(Spontaneous.gem_dir) + "bin/spot publish").expand_path.to_s
        site_root = Pathname.new(Spontaneous.root).expand_path.to_s
        # TODO: make nice value configurable
        FAF.add_task(task_name, publish_binary, 15, {
          "site" => site_root,
          "logfile" => "log/publish.log",
          "environment" => Spontaneous.env
        }, {})
      end

      register_task

      def self.status
        FAF.get_status(task_name)
      end

      def self.status=(status)
        FAF.set_status(task_name, status)
      end

      attr_reader :revision

      def initialize(revision)
        @revision = revision
      end

      def task_name
        self.class.task_name
      end

      def publish_changes(change_list)
        FAF.fire(task_name, {"changes" => change_list})
      end

      def publish_all
        FAF.fire(task_name)
      end
    end # FireAndForget
  end # Publishing
end # Spontaneous

