# encoding: UTF-8

require 'fileutils'

module Spontaneous::Media
  # Represents a temporary file used to provide a media file that is visible
  # publically under a /media/tmp/* URL for passing to file fields for
  # asynchronous processing
  class TempFile < File

    def storage
      Spontaneous::Site.default_storage
    end

    def media_dir
      F.join("tmp", padded_id)
    end

    def storage_path
      ["tmp", padded_id, filename]
    end

    def padded_id
      Spontaneous::Media.pad_id(owner.media_id)
    end
  end
end
