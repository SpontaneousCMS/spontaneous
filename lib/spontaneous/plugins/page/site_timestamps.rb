# encoding: UTF-8

require 'rack'

module Spontaneous::Plugins::Page
  module SiteTimestamps
    extend ActiveSupport::Concern

    def after_update
      ::Spontaneous::State.site_modified! if field?(title_field) && fields[title_field].modified?
      super
    end

    # Update the Site's modification time to force clients
    # to reload their map data
    def after_create
      ::Spontaneous::State.site_modified!
      super
    end

    # Update the Site's modification time to force clients
    # to reload their map data
    def after_destroy
      ::Spontaneous::State.site_modified!
      super
    end
  end
end
