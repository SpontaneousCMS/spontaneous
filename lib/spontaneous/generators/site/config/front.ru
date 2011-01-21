ENV["SPOT_MODE"] = "front"

require File.expand_path("../boot.rb", __FILE__)

puts "Spontaneous::Back running on port #{Spontaneous::Rack.port}"

