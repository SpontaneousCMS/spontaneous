SPOT_ENV = (ENV["SPOT_ENV"] ||= ENV["RACK_ENV"] ||= "development").to_sym unless defined?(SPOT_ENV)
SPOT_MODE = (ENV["SPOT_MODE"] ||= "back").to_sym unless defined?(SPOT_MODE)

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

Bundler.require(:default, SPOT_ENV, SPOT_MODE)

# TODO: configuration of template engine
# so, remove this require and move the template init into part of the ::load! method
# using config settings to determine engine
require 'cutaneous'

Spontaneous.init(:environment => SPOT_ENV, :mode => SPOT_MODE)

