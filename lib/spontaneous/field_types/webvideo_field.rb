# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class WebVideoField < Field
      plugin Spontaneous::Plugins::Field::EditorClass

      def outputs
        [:type, :id]
      end

      def id
        value(:id)
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
          values[:id] = $1
          values[:type] = "youtube"
        when /vimeo\.com\/(\d+)/
          values[:id] = $1
          values[:type] = "vimeo"
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


      def ui_preview_value
        render(:html, :width => 480, :height => 270)
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
          :player_id => "vimeo#{owner.id}id#{value(:id)}"
        }.merge(o).merge(vimeo_options).merge(options)

        attributes = {
          :type => "text/html",
          :frameborder => "0",
          :width => o.delete(:width),
          :height => o.delete(:height)
        }
        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

        make_query_options!(o)

        attributes[:src] = "http://player.vimeo.com/video/#{value(:id)}?title=#{o[:title]}&byline=#{o[:byline]}&portrait=#{o[:portrait]}&autoplay=#{o[:autoplay]}&loop=#{o[:loop]}&api=#{o[:api]}&player_id=#{o[:player_id]}#{o.key?(:color) ? "&color=#{o[:color]}" : ""}"

        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}

      end


      def to_youtube_html(options = {})
        params = youtube_attributes(options)
        attributes = make_html_attributes(params[:attr])
        %(<iframe #{attributes}></iframe>)
      end


      def youtube_attributes(options = {})

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

        attributes = {
          :type => "text/html",
          :frameborder => "0",
          :width => o.delete(:width),
          :height => o.delete(:height)
        }

        make_query_options!(o)

        attributes[:src] = "http://www.youtube.com/embed/#{value(:id)}?modestbranding=1&theme=#{o[:theme]}&hd=#{o[:hd]}&fs=#{o[:fullscreen]}&controls=#{o[:controls]}&autoplay=#{o[:autoplay]}&showinfo=#{o[:showinfo]}&showsearch=#{o[:showsearch]}&loop=#{o[:loop]}&autohide=#{o[:autohide]}&rel=#{o[:rel]}&enablejsapi=#{o[:api]}"
        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]


        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
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
end

