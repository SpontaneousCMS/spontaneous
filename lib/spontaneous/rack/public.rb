# encoding: UTF-8


module Spontaneous
  module Rack
    class Public < ServerBase
      set :static, true
      set :public, Proc.new { Spontaneous.root / "public" }

      get "/" do
        Site.root.render
      end

      get '/media/*' do
        send_file(Spontaneous.media_dir / params[:splat].first)
      end

      get "*" do
        if page = Site[params[:splat].first]
          page.render
        else
          404
        end
      end
    end
  end
end

