# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class VimeoField < Field
      plugin Spontaneous::Plugins::Field::EditorClass

      def preprocess(input)
        case input
        when /vimeo\.com\/(\d+)/
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
          :width => 640,
          :height => 360,
          :title => true,
          :byline => true,
          :portrait => true,
          :fullscreen => true
        }.merge(args.extract_options!)
        o.each { |k, v|
          o[k] = 1 if v == true
          o[k] = 0 if v == false
        }
        %(<iframe src="http://player.vimeo.com/video/#{value}?title=#{o[:title]}&amp;byline=#{o[:byline]}&amp;portrait=#{o[:portrait]}" width="#{o[:width]}" height="#{o[:height]}" frameborder="0" #{o[:fullscreen] == 1 ? "webkitAllowFullScreen allowFullScreen" : ""}></iframe>)
      end
    end

    VimeoField.register(:vimeo)
  end
end

