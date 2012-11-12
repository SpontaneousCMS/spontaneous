# encoding: UTF-8

module Spontaneous::Plugins
  module Media
    extend Spontaneous::Concern

    # InstanceMethods

    def media_filepath(*args)
      File.join(Spontaneous.media_dir, padded_id, padded_revision, *args)
    end

    def media_urlpath(*args)
      File.join("/media", padded_id, padded_revision, *args)
    end

    def padded_id
      save if media_id.nil?
      media_id.to_s.rjust(5, "0")
    end

    def media_id
      id
    end

    def padded_revision
      Spontaneous::Site.working_revision.to_s.rjust(4, "0")
    end
  end
end
