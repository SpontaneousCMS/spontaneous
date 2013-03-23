require 'skeptick'

module Skeptick
  module Sugar
    module Fitting
      def width(width, options = {})
        options = make_options(options, :width => width)
        set :resize, geometry(options)
      end

      def height(height, options = {})
        options = make_options(options, :height => height)
        set :resize, geometry(options)
      end

      # Implements #resize_to_fit
      def fit(options = {})
        options = make_options(options)
        set :resize, geometry(options)
      end

      # Implements #resize_to_fill
      def fill(options = {})
        gravity = options.delete(:gravity) || "Center"
        defaults = {
          :left  => 0,
          :top   => 0,
          :exact => true
        }
        options = make_options(options, defaults)

        size = options.select { |k, v| [:width, :height, :shrink_only].include?(k) }

        set :geometry, "#{geometry(size)}^"
        set :gravity,  gravity
        set :crop,     geometry(options)
      end

      def greyscale
        set :type, "Grayscale"
      end

      alias_method :grayscale, :greyscale

      # def rounded(radius)
      #     rounded_corners_image(self, :radius => radius)
      # end

      def make_options(options, defaults = {})
        enlarge = options.delete(:enlarge) || false
        defaults.merge(:shrink_only => !enlarge).merge(options)
      end
    end
  end

  include Sugar::Fitting

  class   Image::DslContext; include Sugar::Fitting end
  class Convert::DslContext; include Sugar::Fitting end
end

module Spontaneous::Media
  module Image
    module Skeptick
      include ::Skeptick
    end
  end
end
