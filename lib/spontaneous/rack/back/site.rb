module Spontaneous::Rack::Back
  class Site < Base
    SS = Spontaneous::Site

    get '/?' do
      json({
        :types => SS.schema.export(user),
        :roots => SS.roots(user, content_model),
        :user  => user.export,
        :services => (SS.config.services || [])
      })
    end

    get '/home' do
      json SS.root
    end

    post '/home' do
      forbidden! unless SS.root.nil?
      type = content_model.schema.to_class(params[:type])
      root = type.create(:title => "Home")
      json({:id => root.id})
    end
  end
end
