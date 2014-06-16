# encoding: UTF-8

module Spontaneous::Model::Page
  # Various scenarios where we need to Update the Site's modification
  # time to force clients to reload their map data
  module SiteTimestamps
    extend Spontaneous::Concern

    def before_save_field(field)
      mark_site_modified if ((field.name == title_field_name) && field.modified?)
      super
    end

    # The UI map uses the slugs for the pulldown values so changes to the
    # slug must force a reload or things get very odd.
    def before_update
      mark_site_modified if changed_columns.include?(:slug)
      super
    end

    def after_update
      mark_site_modified if field?(title_field_name) && fields[title_field_name].modified?
      super
    end

    def after_create
      mark_site_modified
      super
    end

    # Update the Site's modification time to force clients
    # to reload their map data
    def after_destroy
      mark_site_modified
      super
    end

    protected

    def mark_site_modified
      ::Spontaneous::State.site_modified!
    end
  end
end
