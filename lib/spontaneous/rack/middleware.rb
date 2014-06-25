
module Spontaneous::Rack::Middleware
end

require "spontaneous/rack/middleware/authenticate"
require "spontaneous/rack/middleware/csrf"
require "spontaneous/rack/middleware/reloader"
require "spontaneous/rack/middleware/scope"
require "spontaneous/rack/middleware/transaction"
