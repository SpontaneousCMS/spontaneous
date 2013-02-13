module Spontaneous::Rack::Back
  class Changes < Base
    before do
      forbidden! unless user.level.can_publish?
    end

    get '/?' do
      json(Spontaneous::Change)
    end

    post '/?' do
      ids = params[:page_ids]
      halt 400 if ids.blank? || ids.empty?
      pages = ids.map(&:to_i)
      Spontaneous::Site.publish_pages(pages)
      json({})
    end
  end
end
