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
        path = remove_trailing_slashes(params[:splat].first)
        page = site[path]
        json site.map(page.id)
      end
    end

    def remove_trailing_slashes(path)
      path.gsub(/\/+$/, '')
    end
  end
end
