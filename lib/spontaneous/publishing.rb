# encoding: UTF-8

module Spontaneous
  module Publishing
    autoload :Immediate,      "spontaneous/publishing/immediate"
    autoload :Threaded,       "spontaneous/publishing/threaded"
    autoload :Simultaneous,   "spontaneous/publishing/simultaneous"
    autoload :EventClient,    "spontaneous/publishing/event_client"
    autoload :Revision,       "spontaneous/publishing/revision"
  end # Publishing
end # Spontaneous

