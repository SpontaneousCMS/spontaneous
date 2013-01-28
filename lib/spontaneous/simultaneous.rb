require 'simultaneous'

module Spontaneous
  module Simultaneous

    class Error < Spontaneous::Error; end

    module ModuleMethods
      def simultaneous_setup
        ::Simultaneous.client_mode  = :async
        ::Simultaneous.connection   = ::Spontaneous.config.simultaneous_connection
        ::Simultaneous.domain       = ::Spontaneous.config.site_domain
      end

      def register(task_name, task, options = {}, params = {}, env = {})
        options.update({
          :pwd => root
        })
        params.update({
          "site" => root,
          "environment" => Spontaneous.env
        })
        ::Simultaneous.add_task(task_name, binary(task), options, params, env)
      end

      def fire(task_name, params = {})
        ::Simultaneous.fire(task_name, params)
      rescue => e
        raise Error, e
      end

      def spot_binary
        ::Spontaneous.config.spontaneous_binary || default_spot_binary
      end

      def default_spot_binary
        (Pathname.new(Spontaneous.gem_dir) + "bin/spot").expand_path.to_s
      end

      def binary(task)
        [spot_binary, task].join(" ")
      end

      def root
        Pathname.new(Spontaneous.root).expand_path.to_s
      end
    end

    extend ModuleMethods

    simultaneous_setup
  end
end
