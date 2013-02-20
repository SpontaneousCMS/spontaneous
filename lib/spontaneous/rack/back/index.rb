module Spontaneous::Rack::Back
  class Index < Base
    include TemplateHelpers

    # Matches either:
    #   /@spontaneous
    #   /@spontaneous/
    #   /@spontaneous/xxx/edit
    #   /@spontaneous/xxx/preview
    #
    # where xxx is a numeric id
    get %r{\A(/?|/(\d+/?.*)?)\z} do
      erb :index
    end
  end
end
