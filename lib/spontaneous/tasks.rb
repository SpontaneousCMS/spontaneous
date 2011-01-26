Dir["#{File.dirname(__FILE__)}/tasks/**/*.rake"].each { |ext| load ext }

# Load the custom, site-specific tasks
Dir["#{Spontaneous.root}/lib/tasks/**/*.rake"].each { |ext| load ext }
# TODO: load the role tasks
