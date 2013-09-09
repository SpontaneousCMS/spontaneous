# encoding: UTF-8

module Spontaneous::Field
  class WebVideo
    class Fallback < Provider
      def self.id
        "fallback"
      end

      def to_html(options = {})
        params = player_attributes(options)
        attributes = hash_to_attributes(params[:attr])
        %(<iframe #{attributes}></iframe>)
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

        attributes[:src] = @field.unprocessed_value

        attributes.update(:webkitAllowFullScreen => "yes", :allowFullScreen => "yes") if o[:fullscreen]

        {:tagname => "iframe", :tag => "<iframe/>", :attr => attributes}
      end

      def player_options(options = {})
        default_player_options.merge(options)
      end
    end
    Spontaneous::Field::WebVideo.provider Fallback
  end
end
