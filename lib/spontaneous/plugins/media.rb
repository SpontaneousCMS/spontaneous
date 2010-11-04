# encoding: UTF-8

module Spontaneous::Plugins
  module Media
    module ClassMethods
    end

    module InstanceMethods
      def media_filepath(*args)
        File.join(Spontaneous.media_dir, id.to_s, Spontaneous::Site.working_revision.to_s, *args)
      end

      def media_urlpath(*args)
        File.join("/media", id.to_s, Spontaneous::Site.working_revision.to_s, *args)
      end

      def make_media_file(src_file)
        media_filepath = media_filepath(File.basename(src_file))
        FileUtils.mkdir_p(File.dirname(media_filepath))
        FileUtils.mv(src_file, media_filepath)
        media_filepath
      end
    end
  end
end


