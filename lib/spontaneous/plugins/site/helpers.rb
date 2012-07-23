# encoding: UTF-8


module Spontaneous::Plugins::Site
  module Helpers
    extend ActiveSupport::Concern

    module ClassMethods
      def helper(*formats, &block)
        helper_module = Module.new(&block)
        register_helper(helper_module, *formats.flatten)
        helper_module
      end

      # Private: Generates a module including all helper methods for the requested format(s)
      def context(*formats)
        formats = [:*].concat formats.flatten.map { |f| f.to_sym }
        helper_module = Module.new
        formats.each do |format|
          Spontaneous::Output::Helpers.registered_helpers[format].each do |mod|
            helper_module.send :include, mod
            helper_module.send :extend,  mod
          end
          Spontaneous::Site.registered_helpers[format].each do |mod|
            helper_module.send :include, mod
            helper_module.send :extend,  mod
          end
        end
        helper_module
      end

      def register_helper(helper_module, *formats)
        site = instance
        if formats.empty?
          site.registered_helpers[:*] << helper_module
        else
          formats.each do |format|
            site.registered_helpers[format.to_sym] << helper_module
          end
        end
      end

      def registered_helpers
        instance.registered_helpers
      end
    end

    def registered_helpers
      @registered_helpers ||= Hash.new { |hash, key| hash[key] = [] }
    end
  end # Helpers
end

