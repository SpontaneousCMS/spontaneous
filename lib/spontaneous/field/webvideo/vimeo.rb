# encoding: UTF-8

require 'open-uri'
require 'rack'

module Spontaneous::Field
  class WebVideo
    class Vimeo < Provider
      def self.match(field, url)
        case url
        when /vimeo\.com\/(\d+)/
          video_id = $1
          new(field, :video_id => video_id, :provider => id).metadata
        else
          nil
        end
      end

      def metadata
        @attributes.update(download_metadata)
      end

      def download_metadata
        url = "http://vimeo.com/api/v2/video/%s.json" % video_id
        response = \
          begin
            open(url).read
        rescue => e
          logger.error("Unable to retrieve metadata for video ##{video_id} from Vimeo: '#{e}'")
          "[{}]"
        end
        metadata = Spontaneous.parse_json(response) rescue [{}]
        metadata = metadata.first || {}
      end

      def to_html(options = {})
        params = player_attributes(options)
        attributes = hash_to_attributes(params[:attr])
        %(<iframe #{attributes}></iframe>)
      end

      def as_json(options = {})
        player_attributes(options)
      end

      def player_attributes(options = {})
        o = player_options(options)

        attributes = {
          :type => "text/html",
          :frameborder => "0",
          :width => o.delete(:width),
          :height => o.delete(:height)
        }
        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

        make_query_options!(o)
        attributes[:src] = src_with_options(o)

        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
      end

      def player_options(options = {})
        o  = default_player_options
        vimeo_options = o.delete(:vimeo) || {}

        o.merge!(vimeo_options)

        if o.delete(:showinfo)
          o[:portrait] = true
          o[:title] = true
          o[:byline] = true
        else
          o[:portrait] = false
          o[:title] = false
          o[:byline] = false
        end

        vimeo_options = options.delete(:vimeo) || {}

        o = {
          :portrait => true,
          :title => true,
          :byline => true,
          :player_id => "vimeo#{@field.id}id#{video_id}"
        }.merge(o).merge(vimeo_options).merge(options)
        o
      end

      def src(options = {})
        o = player_options(options)
        make_query_options!(o)
        src_with_options(o)
      end

      def src_with_options(o)
        params = {
          "title" => o[:title],
          "byline" => o[:byline],
          "portrait" => o[:portrait],
          "autoplay" => o[:autoplay],
          "loop" => o[:loop],
          "api" => o[:api],
          "player_id" => o[:player_id] }
        params.update("color" => o[:color]) if o.key?(:color)
        params = ::Rack::Utils.build_query(params)
        "http://player.vimeo.com/video/#{video_id}?#{params}"
      end
    end

    Spontaneous::Field::WebVideo.provider Vimeo
  end
end
