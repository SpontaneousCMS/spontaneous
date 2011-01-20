SPOT_ENV = ENV["SPOT_ENV"] ||= ENV["RACK_ENV"] ||= "development" unless defined?(SPOT_ENV)

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler'

Bundler.setup(:default, SPOT_ENV.to_sym)
# Bundler.require(:default, SPOT_ENV.to_sym)

require 'spontaneous'
# TODO: configuration of template engine
# so, remove this require and move the template init into part of the ::load! method
# using config settings to determine engine
require 'cutaneous'

Spontaneous.load!(SPOT_ENV)
