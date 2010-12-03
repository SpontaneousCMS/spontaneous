require "rubygems"
require "bundler"
Bundler.setup(:default)

require 'spontaneous'
require 'cutaneous'

env = (ENV['SPOT_ENV'] || 'development').to_sym


Spontaneous.init(:mode => :back, :environment => env)
Spontaneous.database.logger = Logger.new($stdout)

puts "Spontaneous::Back running on port #{Spontaneous::Rack.port}"

