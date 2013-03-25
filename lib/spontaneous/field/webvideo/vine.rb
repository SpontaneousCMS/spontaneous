# encoding: UTF-8

require 'open-uri'
require 'rack'

module Spontaneous::Field
  class WebVideo
    class Vine < Provider
      def self.match(field, url)
        case url
        when /vine\.co\/v\/([^\/&]+)/
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
        {}
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

        dim = o.delete(:width)
        attributes = {
          :type => "text/html",
          :frameborder => "0",
          :width => dim,
          :height => dim
        }
        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

        attributes[:src] = src_with_options(o)

        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
      end

      def player_options(options = {})
        o  = default_player_options
        vine_options = o.delete(:vine) || {}

        o.update(vine_options)

        vine_options = options.delete(:vine) || {}

        o = {
          :player_id => "vime#{@field.id}id#{video_id}"
        }.merge(o).merge(vine_options).merge(options)
        o
      end

      # Vine has no options
      def src(options = {})
        # o = player_options(options)
        # make_query_options!(o)
        o = {}
        src_with_options(o)
      end

      def src_with_options(o)
        # params = {
        #   "title" => o[:title],
        #   "byline" => o[:byline],
        #   "portrait" => o[:portrait],
        #   "autoplay" => o[:autoplay],
        #   "loop" => o[:loop],
        #   "api" => o[:api],
        #   "player_id" => o[:player_id] }
        # params.update("color" => o[:color]) if o.key?(:color)
        # params = ::Rack::Utils.build_query(params)
        "https://vine.co/v/#{video_id}/card"
      end
    end

    Spontaneous::Field::WebVideo.provider Vine
  end
end

