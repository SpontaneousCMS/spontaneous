SPOT_ENV = ENV["SPOT_ENV"] ||= ENV["RACK_ENV"] ||= "development" unless defined?(SPOT_ENV)

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

Bundler.require(:default, SPOT_ENV.to_sym)

# TODO: configuration of template engine
# so, remove this require and move the template init into part of the ::load! method
# using config settings to determine engine
require 'cutaneous'

Spontaneous.init(:environment => SPOT_ENV)
