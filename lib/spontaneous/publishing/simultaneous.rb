# encoding: UTF-8


module Spontaneous
  module Publishing
    class Simultaneous

      def self.task_name
        # TODO: add site name to this to make it unique on a server
        :publish
      end

      def self.register_task
        task = "site publish"
        niceness = Spontaneous::Site.config.publish_niceness || 15
        logfile =  "log/publish.log"
        task_options = {
          :niceness => niceness,
          :logfile  => logfile
        }
        task_params = {}
        Spontaneous::Simultaneous.register(task_name, task, task_options, task_params)
      end

      register_task

      attr_reader :revision

      def initialize(revision, content_model, steps)
        @revision, @content_model = revision, content_model
      end

      def task_name
        self.class.task_name
      end

      def publish_pages(page_list)
        Spontaneous::Simultaneous.fire(task_name, {"pages" => page_list})
      end

      def publish_all
        Spontaneous::Simultaneous.fire(task_name)
      end
    end # Simultaneous
  end # Publishing
end # Spontaneous


