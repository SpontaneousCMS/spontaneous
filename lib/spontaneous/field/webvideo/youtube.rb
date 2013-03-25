# encoding: UTF-8

require 'open-uri'
require 'nokogiri'
require 'rack'

module Spontaneous::Field
  class WebVideo
    class YouTube < Provider

      def self.id
        "youtube"
      end

      def self.match(field, url)
        case url
        when /youtube\.com.*\?.*v=([^&]+)/, /youtu\.be\/([^&]+)/
          video_id = $1
          new(field, :video_id => video_id, :provider => id).metadata
        else
          nil
        end
      end

      def metadata
        @attributes.update(download_metadata)
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

        make_query_options!(o)

        attributes[:src] = src_with_options(o)

        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
      end

      def player_options(options = {})
        o  = default_player_options
        youtube_options = o.delete(:youtube) || {}

        o.update(youtube_options)

        if o.delete(:showinfo)
          o[:showinfo] = true
          o[:showsearch] = true
        else
          o[:showinfo] = false
          o[:showsearch] = false
        end

        youtube_options = options.delete(:youtube) || {}
        o = {
          :theme => "dark",
          :hd => true,
          :controls => true,
          :showinfo => true,
          :showsearch => true,
          :autohide => 2,
          :rel => true
        }.merge(o).merge(youtube_options).merge(options)
      end

      def src(options = {})
        o = player_options(options)
        make_query_options!(o)
        src_with_options(o)
      end

      def src_with_options(o)
        params = ::Rack::Utils.build_query({
          "modestbranding" => 1,
          "theme" => o[:theme],
          "hd" => o[:hd],
          "fs" => o[:fullscreen],
          "controls" => o[:controls],
          "autoplay" => o[:autoplay],
          "showinfo" => o[:showinfo],
          "showsearch" => o[:showsearch],
          "loop" => o[:loop],
          "autohide" => o[:autohide],
          "rel" => o[:rel],
          "enablejsapi" => o[:api] })
        "http://www.youtube.com/embed/#{video_id}?#{params}"
      end

      def download_metadata
        url = "http://gdata.youtube.com/feeds/api/videos/%s?v=2" % video_id
        begin
          doc = Nokogiri::XML(open(url))
          entry = doc.xpath("xmlns:entry")

          { "title" => entry.xpath("xmlns:title").text.strip,
            "description" => entry.xpath("media:group/media:description").text.strip,
            "thumbnail_large" => entry.xpath('media:group/media:thumbnail[@yt:name="hqdefault"]').first["url"].strip,
            "thumbnail_small" => entry.xpath('media:group/media:thumbnail[@yt:name="default"]').first["url"].strip,
            "user_name" => entry.xpath("xmlns:author/xmlns:name").text.strip,
            "upload_date" => Time.parse(entry.xpath("xmlns:published").text.strip).strftime("%Y-%m-%d %H:%M:%S"),
            "tags" => entry.xpath("media:group/media:keywords").text.strip,
            "duration" => entry.xpath("media:group/yt:duration").first['seconds'].to_i,
            "stats_number_of_likes" => entry.xpath("yt:rating").first['numLikes'].to_i,
            "stats_number_of_plays" => entry.xpath("yt:statistics").first['viewCount'].to_i,
            "stats_number_of_comments" => entry.xpath("gd:comments/gd:feedLink").first['countHint'].to_i }
        rescue
          {}
        end
      end

    end

    Spontaneous::Field::WebVideo.provider YouTube
  end
end
