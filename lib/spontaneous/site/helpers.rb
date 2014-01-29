# encoding: UTF-8

class Spontaneous::Site
  module Helpers
    extend Spontaneous::Concern

    # module ClassMethods
      def helper(*formats, &block)
        helper_module = Module.new(&block)
        register_helper(helper_module, helper_module_name(caller), *formats.flatten)
        helper_module
      end

      def helper_module_name(_caller)
        parts = _caller.first.split(':').first.split('/')
        path = parts[-([5, parts.length].min)..-1]
        path.join('_').gsub(/[^A-Za-z_]/, '_').gsub(/_+/, '_').gsub(/^_+/, '').capitalize
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
          registered_helpers[format].each do |mod|
            helper_module.send :include, mod
            helper_module.send :extend,  mod
          end
        end
        helper_module
      end

      def register_helper(helper_module, module_name, *formats)
        site = self
        helpers = registered_helpers
        if formats.empty?
           helpers[:*] << helper_module
        else
          formats.each do |format|
            helpers[format.to_sym] << helper_module
          end
        end
        def helper_module.__finalize
          site.unregister_helper(self)
        end
      end

      def unregister_helper(helper_module)
        helpers = registered_helpers
        helpers.each do |format, helpers|
          helpers.delete(helper_module)
        end
      end

    # end

    def registered_helpers
      @registered_helpers ||= Hash.new { |hash, key| hash[key] = [] }
    end
  end # Helpers
end

