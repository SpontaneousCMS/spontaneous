
module Spontaneous
  module Rack
    class Media < ::Sinatra::Base
      set :environment, Proc.new { Spontaneous.environment }
      # set :static, true
      # set :public, Proc.new { Spontaneous.root / "public" }

      get '*' do
        send_file(Spontaneous.media_dir / params[:splat].first)
      end
    end
  end
end
