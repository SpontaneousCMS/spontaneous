module Spontaneous::Rack::Middleware
  autoload :Authenticate, "spontaneous/rack/middleware/authenticate"
  autoload :CSRF,         "spontaneous/rack/middleware/csrf"
  autoload :Reloader,     "spontaneous/rack/middleware/reloader"
  autoload :Scope,        "spontaneous/rack/middleware/scope"
end
