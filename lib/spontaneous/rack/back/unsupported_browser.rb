module Spontaneous::Rack::Back
  class UnsupportedBrowser < Base
    get '/unsupported' do
      erb :unsupported
    end
  end
end
