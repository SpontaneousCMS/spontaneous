module Spontaneous::Rack::Back
  class Site < Base
    SS = Spontaneous::Site

    get "/site" do
      json({
        :types => SS.schema.export(user),
        :user  => user.export,
        :services => (SS.config.services || [])
      })
    end

    get '/site/home' do
      json SS.root
    end

    post '/site/home' do
      forbidden! unless SS.root.nil?
      type = content_model.schema.to_class(params[:type])
      root = type.create(:title => "Home")
      json({:id => root.id})
    end
  end
end
