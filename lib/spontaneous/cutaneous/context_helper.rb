
module Spontaneous::Cutaneous
  module ContextHelper
    include Tenjin::ContextHelper
    ## over-ride this in implementations
    def format
      :html
    end

    def include(filename)
      import(filename)
    end
  end
end
