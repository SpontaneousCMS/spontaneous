# encoding: UTF-8


module Spontaneous
  module Rack
    class Public < ServerBase
      set :static, true
      set :public, Proc.new { Spontaneous.root / "public" }
      get "/" do
        Site.root.render
      end

      get "*" do
        Site[params[:splat].first].render
      end
    end
  end
end

