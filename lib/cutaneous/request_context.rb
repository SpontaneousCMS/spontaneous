# encoding: UTF-8

module Cutaneous
  class RequestContext
    include ContextHelper
    include Spontaneous::Render::RequestContext
  end
end

