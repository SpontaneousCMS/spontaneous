module Spontaneous::Rack::Back
  class Private < Base
    include Spontaneous::Rack::Public

    get '/:id.?:format?' do
      content_for_request { |page|
        _render_page_with_output(page, "html", {})
      }
    end
  end
end
