require "rubygems"
require "bundler"
Bundler.setup(:default)

require 'spontaneous'
require 'cutaneous'

env = (ENV['SPOT_ENV'] || 'development').to_sym


Spontaneous.init(:mode => :front, :environment => env)
Spontaneous.database.logger = Logger.new($stdout)


puts "Spontaneous::Front running on port #{Spontaneous::Rack.port}"
