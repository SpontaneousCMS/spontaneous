require "rubygems"
require "bundler"
Bundler.setup(:default)
Bundler.require

$:.unshift(File.expand_path(File.dirname(__FILE__) + '../../../../../lib'))
require 'spontaneous'
require 'cutaneous'

env = (ENV['SPON_ENV'] || 'development').to_sym

Dir.chdir('test/fixtures/example_application')

Spontaneous.init(:mode => :back, :environment => :development)
Spontaneous.database.logger = Logger.new($stdout)


puts "Spontaneous::Back running on port #{Spontaneous::Rack.port}"
run Spontaneous::Rack::Back.application.to_app

