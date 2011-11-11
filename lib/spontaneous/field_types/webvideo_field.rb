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
        id = nil
        values[:html] = escape_html(input)
        case input
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
      # def preprocess(input)
      #   id = nil
      #   case input
      #   when /youtube\\.com.*\\?.*v=([^&]+)/, /youtu.be\\/([^&]+)/
      #     id = $1
      #     type = "youtube"
      #   else
      #     input
      #   end
      # end

      def render(format=:html, *args)
        case format
        when :html
          to_html(*args)
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


      def ui_preview_value
        render(:html, :width => 480, :height => 270)
      end


      def default_player_options
        {
          :width => 640,
          :height => 360,
          :fullscreen => true,
          :autoplay => false,
          :loop => false,
          :showinfo => true
        }.merge(prototype.options[:player] || {})
      end


      def to_vimeo_html(options = {})
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
          :byline => true
        }.merge(o).merge(options).merge(vimeo_options)

        make_query_options!(o)

        %(<iframe src="http://player.vimeo.com/video/#{value(:id)}?title=#{o[:title]}&amp;byline=#{o[:byline]}&amp;portrait=#{o[:portrait]}&amp;autoplay=#{o[:autoplay]}&amp;loop=#{o[:loop]}#{o.key?(:color) ? "&amp;color=#{o[:color]}" : ""}" width="#{o[:width]}" height="#{o[:height]}" frameborder="0" #{o[:fullscreen] == 1 ? "webkitAllowFullScreen allowFullScreen" : ""}></iframe>)
      end

      def to_youtube_html(options = {})
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
          :showsearch => true
        }.merge(o).merge(options).merge(youtube_options)

        make_query_options!(o)

        %(<iframe id="youtube-#{owner.id}" type="text/html" width="#{o[:width]}" height="#{o[:height]}" src="http://www.youtube.com/embed/#{value(:id)}?modestbranding=1&amp;theme=#{o[:theme]}&amp;hd=#{o[:hd]}&amp;fs=#{o[:fullscreen]}&amp;controls=#{o[:controls]}&amp;autoplay=#{o[:autoplay]}&amp;showinfo=#{o[:showinfo]}&amp;showsearch=#{o[:showsearch]}&amp;loop=#{o[:loop]}" frameborder="0"></iframe>)
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

