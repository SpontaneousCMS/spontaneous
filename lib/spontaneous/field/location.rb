# encoding: UTF-8

require 'open-uri'

module Spontaneous::Field
  class Location < String

    def outputs
      [:html, :lat, :lng]
    end

    def generate_outputs(input, site)
      values = {}
      values[:html] = escape_html(input)
      values.update(geolocate(input))
      values
    end

    def geolocate(address)
      return {} if address.blank?
      url = "http://maps.google.com/maps/api/geocode/json?address=#{URI.escape(address)}&sensor=false"

      response = open(url).read rescue "{}"
      data = Spontaneous.parse_json(response) rescue {}
      return {} unless data[:results]
      # bad/unknown addresses return `{:results=>[], :status=>"ZERO_RESULTS"}`
      values = {}
      result = data[:results].first
      return {} if result.nil?
      values[:formatted_address] = result[:formatted_address]
      geometry = result[:geometry]
      values[:lat] = geometry[:location][:lat]
      values[:lng] = geometry[:location][:lng]
      country = (result[:address_components].detect { |c| c[:types].first == "country" } || {})[:long_name]
      values[:country] = country
      values
    end

    def latitude
      value(:lat)
    end

    def longitude
      value(:lng)
    end

    def country
      value(:country)
    end

    def formatted_address
      value(:formatted_address)
    end

    alias_method :lat, :latitude
    alias_method :lng, :longitude

    self.register
  end # LongStringField
end

