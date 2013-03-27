# encoding: UTF-8

require 'open-uri'
require 'nokogiri'
require 'erb'

module Spontaneous::Field
  class WebVideo < Base
    has_editor

    class Provider
      def self.id
        name.demodulize.underscore
      end

      def self.match(field, url)
        # Implement in subclasses
      end

      attr_reader :attributes

      def initialize(field, attributes = {})
        @field, @attributes = field, attributes
      end

      def metadata
        @attributes
      end

      def video_id
        attributes[:video_id]
      end

      def src(options = {})
        # Implement in subclasses
        video_id
      end

      # Don't show an unknown/default provider in the template
      #
      # TODO: Make default provider use the oembed api to create the right
      # embed code for any video service (that supports the oembed system)
      # Difficulty will be making that embed code adaptable to sizes configured
      # in the field prototype & templates.
      def to_html(options = {})
        ""
      end

      def as_json(options = {})
        {}
      end

      def default_player_options
        { :width => 640,
          :height => 360,
          :fullscreen => true,
          :api => false,
          :autoplay => false,
          :loop => false,
          :showinfo => true
        }.merge(@field.prototype.options[:player] || {})
      end

      def hash_to_attributes(attributes)
        attributes.to_a.map { |name, value| "#{name}=\"#{escape_html(value)}\"" }.join(" ")
      end

      def escape_html(input)
        ERB::Util.html_escape(input)
      end

      def make_query_options!(hash)
        hash.each { |k, v|
          hash[k] = 1 if v == true
          hash[k] = 0 if v == false
        }
      end
    end

    def self.providers
      @providers ||= {
        nil => Spontaneous::Field::WebVideo::Provider
      }
    end

    def self.provider(provider)
      providers[provider.id] = provider
    end

    def outputs
      [:provider, :video_id]
    end

    # Earlier versions used :id to store the video id
    # so to support them I need to try it first.
    def video_id
      values[:video_id]
    end

    def generate_outputs(input)
      values = {}
      values[:html] = escape_html(input)

      metadata = nil
      Spontaneous::Field::WebVideo.providers.each do |_, p|
        break if metadata = p.match(self, input)
      end
      metadata ||= Provider.new(self, :video_id => input, :provider => nil).metadata
      values.merge(metadata || {})
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
      provider.to_html(*args)
    end

    def provider_id
      values[:provider]
    end

    def provider
      provider = Spontaneous::Field::WebVideo.providers[provider_id]
      provider.new(self, values)
    end

    def to_json(*args)
      opts = args.extract_options!
      Spontaneous.encode_json(provider.as_json(opts))
    end

    def src(opts = {})
      provider.src(opts)
    end

    def ui_preview_value
      # render(:html, :width => 480, :height => 270)
      src
    end

    self.register(:webvideo)
  end
end

Dir[::File.dirname(__FILE__) + "/webvideo/*.rb"].each do |provider|
  require provider
end
