# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class YouTubeField < Field
      plugin Spontaneous::Plugins::Field::EditorClass

      def preprocess(input)
        case input
        when /youtube\.com.*\?.*v=([^&]+)/, /youtu.be\/([^&]+)/
          $1
        else
          input
        end
      end

      def render(format=:html, *args)
        case format
        when :html
          to_html(*args)
        else
          value(format)
        end
      end

      def to_html(*args)
        o = {
          :theme => "dark",
          :hd => 1,
          :fullscreen => 1,
          :controls => 1,
          :autoplay => 0,
          :showinfo => 1,
          :showsearch => 0
        }.merge(args.extract_options!)
        o.each { |k, v|
          o[k] = 1 if v == true
          o[k] = 0 if v == false
        }
        %(<iframe id="youtube-#{owner.id}" type="text/html" width="#{o[:width]}" height="#{o[:height]}" src="http://www.youtube.com/embed/#{value}?modestbranding=1&amp;theme=#{o[:theme]}&amp;hd=#{o[:hd]}&amp;fs=#{o[:fullscreen]}&amp;controls=#{o[:controls]}&amp;autoplay=#{o[:autoplay]}&amp;showinfo=#{o[:showinfo]}&amp;showsearch=#{o[:showsearch]}" frameborder="0"></iframe>)
      end
    end

    YouTubeField.register(:youtube)
  end
end
