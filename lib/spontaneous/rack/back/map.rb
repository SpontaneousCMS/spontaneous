module Spontaneous::Rack::Back
  class Map < Base
    get '/map/?:id?' do
      last_modified(Spontaneous::Site.modified_at)
      map = Spontaneous::Site.map(params[:id])
      if map
        json(map)
      else
        404
      end
    end

    get '/map/path*' do
      last_modified(Spontaneous::Site.modified_at)
      if content_model::Page.count == 0
        406
      else
        path = params[:splat].first
        page = Spontaneous::Site[path]
        json Spontaneous::Site.map(page.id)
      end
    end
  end
end
