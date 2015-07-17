# encoding: UTF-8


module Spontaneous
  module Publishing
    class Simultaneous

      def self.publish_task
        [:publish, "site publish"]
      end

      def self.rerender_task
        [:rerender, "site render"]
      end

      def self.reindex_task
        [:reindex, "site index"]
      end

      def self.register_tasks
        niceness = Spontaneous::Site.config.publish_niceness || 15
        task_options = {
          niceness: niceness,
          logfile: "log/publish.log"
        }
        [publish_task, rerender_task, reindex_task].each do |task_name, task_cmd|
          Spontaneous::Simultaneous.register(task_name, task_cmd, task_options, task_params = {})
        end
      end

      register_tasks

      attr_reader :revision

      def initialize(revision, content_model, steps)
        @revision, @content_model = revision, content_model
      end

      def publish_pages(page_list, user = nil)
        Spontaneous::Simultaneous.fire(:publish, {"pages" => page_list, "user" => user.try(:id)})
      end

      def publish_all(user = nil)
        Spontaneous::Simultaneous.fire(:publish, {"user" => user.try(:id)})
      end

      def rerender
        Spontaneous::Simultaneous.fire(:rerender)
      end

      def rerender
        Spontaneous::Simultaneous.fire(:reindex)
      end
    end # Simultaneous
  end # Publishing
end # Spontaneous


