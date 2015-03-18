module Spontaneous::Rack::Back
  class Changes < Base
    before do
      forbidden! unless user.level.can_publish?
    end

    get '/?' do
      json(Spontaneous::Change.export(site))
    end

    post '/?' do
      ids = params[:page_ids]
      halt 400 if ids.blank? || ids.empty?
      pages = ids.map(&:to_i)
      site.publish_pages(pages, user)
      json({})
    end

    post '/rerender' do
      site.rerender
      json({})
    end

    post '/rerender' do
      site.rerender
      json({})
    end
  end
end
