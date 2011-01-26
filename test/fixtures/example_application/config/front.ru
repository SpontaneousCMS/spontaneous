ENV["SPOT_MODE"] = "front"

require File.expand_path("../boot.rb", __FILE__)

logger.info { "Spontaneous::Front running on port #{Spontaneous::Rack.port}" }

run Spontaneous::Rack::Front.application.to_app

