
module Spontaneous
  module Rack
    class Media < ::Sinatra::Base
      set :environment, Proc.new { Spontaneous.environment }
      # set :static, true
      # set :public, Proc.new { Spontaneous.root / "public" }

      get '*' do
        media_file = (Spontaneous.media_dir / params[:splat].first)
        if File.exists?(media_file)
          send_file(media_file)
        else
          redirect("/@spontaneous/static/missing.png")
        end
      end
    end
  end
end
