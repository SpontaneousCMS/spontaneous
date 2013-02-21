# encoding: UTF-8

require 'open-uri'
require 'nokogiri'

module Spontaneous::Field
  class WebVideo < Base
    has_editor

    def outputs
      [:type, :video_id]
    end

    def video_id
      value(:video_id)
    end

    def video_type
      value(:type)
    end


    def generate_outputs(input)
      values = {}
      values[:html] = escape_html(input)
      case input
      when "", nil
        # ignore this
      when /youtube\.com.*\?.*v=([^&]+)/, /youtu.be\/([^&]+)/
        video_id = $1
        values.update(retrieve_youtube_metadata(video_id))
        values[:video_id] = video_id.to_s
        values[:type] = "youtube"
      when /vimeo\.com\/(\d+)/
        video_id = $1
        values[:type] = "vimeo"
        values.update(retrieve_vimeo_metadata(video_id))
        values[:video_id] = video_id.to_s
      else
        logger.warn "WebVideo field doesn't recognise the URL '#{input}'"
      end
      values
    end


    def render(format=:html, *args)
      case format
      when :html
        to_html(*args)
      when :json
        to_json(*args)
      else
        value(format)
      end
    end


    def to_html(*args)
      opts = args.extract_options!
      case video_type
      when "youtube"
        to_youtube_html(opts)
      when "vimeo"
        to_vimeo_html(opts)
      else
        value(:html)
      end
    end


    def to_json(*args)
      opts = args.extract_options!
      params = \
        case video_type
      when "youtube"
        youtube_attributes(opts)
      when "vimeo"
        vimeo_attributes(opts)
      else
        {:tagname => "iframe", :tag => "<iframe/>", :attr => {:src => value(:html)}}
      end
      Spontaneous.encode_json(params)
    end

    def src(opts = {})
      case video_type
      when "youtube"
        youtube_src(opts)
      when "vimeo"
        vimeo_src(opts)
      else
        value(:html)
      end
    end

    def ui_preview_value
      # render(:html, :width => 480, :height => 270)
      src
    end

    def retrieve_vimeo_metadata(video_id)
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

    def retrieve_youtube_metadata(video_id)
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

    def default_player_options
      {
        :width => 640,
        :height => 360,
        :fullscreen => true,
        :api => false,
        :autoplay => false,
        :loop => false,
        :showinfo => true
      }.merge(prototype.options[:player] || {})
    end


    def to_vimeo_html(options = {})
      params = vimeo_attributes(options)

      attributes = make_html_attributes(params[:attr])
      %(<iframe #{attributes}></iframe>)
    end

    def vimeo_attributes(options = {})

      o = make_vimeo_options(options)

      attributes = {
        :type => "text/html",
        :frameborder => "0",
        :width => o.delete(:width),
        :height => o.delete(:height)
      }
      attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

      make_query_options!(o)
      attributes[:src] = vimeo_src_with_options(o)

      {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
    end

    def make_vimeo_options(options = {})
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
        :player_id => "vimeo#{owner.id}id#{value(:video_id)}"
      }.merge(o).merge(vimeo_options).merge(options)
      o
    end

    def vimeo_src(options = {})
      o = make_vimeo_options(options)
      make_query_options!(o)
      vimeo_src_with_options(o)
    end

    def vimeo_src_with_options(o)
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
        id = value(:id) || value(:video_id)
        "http://player.vimeo.com/video/#{id}?#{params}"
    end

    def to_youtube_html(options = {})
      params = youtube_attributes(options)
      attributes = make_html_attributes(params[:attr])
      %(<iframe #{attributes}></iframe>)
    end


    def youtube_attributes(options = {})
      o = make_youtube_options(options)

      attributes = {
        :type => "text/html",
        :frameborder => "0",
        :width => o.delete(:width),
        :height => o.delete(:height)
      }

      make_query_options!(o)

      attributes[:src] = youtube_src_with_options(o)

      attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

      {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
    end

    def make_youtube_options(options = {})
      o  = default_player_options
      youtube_options = o.delete(:youtube) || {}

      o.merge!(youtube_options)

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

    def youtube_src(options = {})
      o = make_youtube_options(options)
      make_query_options!(o)
      youtube_src_with_options(o)
    end

    def youtube_src_with_options(o)
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
        id = value(:id) || value(:video_id)
        "http://www.youtube.com/embed/#{id}?#{params}"
    end

    def make_html_attributes(attributes)
      attributes.to_a.map { |name, value| "#{name}=\"#{escape_html(value)}\"" }.join(" ")
    end


    def make_query_options!(hash)
      hash.each { |k, v|
        hash[k] = 1 if v == true
        hash[k] = 0 if v == false
      }
    end

    self.register(:webvideo)
  end
end
