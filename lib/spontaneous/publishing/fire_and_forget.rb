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
        publish_binary = (Pathname.new(Spontaneous.gem_dir) + "/bin/spot publish").to_s
        site_root = Pathname.new(Spontaneous.root).to_s
        # TODO: make nice value configurable
        FAF.add_task(task_name, publish_binary, 15, {
          "site" => site_root,
          "environment" => Spontaneous.env
        }, {})
      end

      register_task

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

