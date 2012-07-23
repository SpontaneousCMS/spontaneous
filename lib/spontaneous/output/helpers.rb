# encoding: UTF-8

module Spontaneous::Output
  module Helpers
    # Helpers needs a separate helper registration mechanism outside of the Site scope
    # because loading of these modules happens before we instantiate the site object.
    # I don't want to pass calls to Site.register_helper here because Site based helpers
    # should be disposed of with the Site instance whereas these core helpers should persist
    def self.register_helper(helper_module, *formats)
      if formats.empty?
        registered_helpers[:*] << helper_module
      else
        formats.each do |format|
          registered_helpers[format.to_sym] << helper_module
        end
      end
    end

    def self.registered_helpers
      @registered_helpers ||= Hash.new { |hash, key| hash[key] = [] }
    end

    require 'spontaneous/output/helpers/stylesheet_helper'
    require 'spontaneous/output/helpers/script_helper'
    require 'spontaneous/output/helpers/classes_helper'
    require 'spontaneous/output/helpers/conditional_comment_helper'
  end
end
