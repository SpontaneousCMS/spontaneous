ENV["SPOT_MODE"] = "back"

require File.expand_path("../boot.rb", __FILE__)

puts "Spontaneous::Frong running on port #{Spontaneous::Rack.port}"
