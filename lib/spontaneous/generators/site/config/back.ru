ENV["SPOT_MODE"] = "back"

require File.expand_path("../boot.rb", __FILE__)

logger.info { "Spontaneous::Back running on port #{Spontaneous::Rack.port}" }

run Spontaneous::Rack::Back.application.to_app
