# encoding: UTF-8

module Spontaneous
  module Publishing
    autoload :Immediate, "spontaneous/publishing/immediate"
    autoload :Forked, "spontaneous/publishing/forked"
    autoload :FireAndForget, "spontaneous/publishing/fire_and_forget"
  end # Publishing
end # Spontaneous

