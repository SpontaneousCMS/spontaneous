module Spontaneous::Rack::Back
  class Site < Base

    get '/?' do
      json({
        types: site.schema.export(user),
        roots: site.roots(user),
        user: user.export,
        services: (site.config.services || [])
      })
    end

    get '/home' do
      json site.home
    end

    post '/home' do
      forbidden! unless site.home.nil?
      type = content_model.schema.to_class(params[:type])
      root = type.create(:title => "Home")
      json({:id => root.id})
    end
  end
end
