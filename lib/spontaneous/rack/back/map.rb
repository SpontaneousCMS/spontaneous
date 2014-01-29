module Spontaneous::Rack::Back
  class Map < Base
    get '/?:id?' do
      last_modified(site.modified_at)
      map = site.map(params[:id])
      if map
        json(map)
      else
        404
      end
    end

    get '/path*' do
      last_modified(site.modified_at)
      if content_model::Page.count == 0
        406
      else
        path = params[:splat].first
        page = site[path]
        json site.map(page.id)
      end
    end
  end
end
