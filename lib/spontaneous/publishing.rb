# encoding: UTF-8

module Spontaneous
  module Publishing
    autoload :Immediate,    "spontaneous/publishing/immediate"
    autoload :Threaded,     "spontaneous/publishing/threaded"
    autoload :Simultaneous, "spontaneous/publishing/simultaneous"
    autoload :EventClient,  "spontaneous/publishing/event_client"
    autoload :Revision,     "spontaneous/publishing/revision"
    autoload :Steps,        "spontaneous/publishing/steps"
    autoload :Progress,     "spontaneous/publishing/progress"
    autoload :Pipeline,     "spontaneous/publishing/pipeline"
    autoload :Publish,      "spontaneous/publishing/publish"
    autoload :Reindex,      "spontaneous/publishing/reindex"
    autoload :Rerender,     "spontaneous/publishing/rerender"
    autoload :Transaction,  "spontaneous/publishing/transaction"
  end # Publishing
end # Spontaneous
